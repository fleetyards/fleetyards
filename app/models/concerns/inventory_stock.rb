# frozen_string_literal: true

module InventoryStock
  extend ActiveSupport::Concern

  DEFAULT_SORTING_PARAMS = ["name asc"]
  ALLOWED_SORTING_PARAMS = [
    "name asc", "name desc",
    "createdAt asc", "createdAt desc",
    "updatedAt asc", "updatedAt desc"
  ]

  included do
    before_save :update_slugs

    # Goods a pending transfer dispatched are represented by an ordinary
    # withdrawal on this inventory. Destroying it would take that withdrawal
    # with it -- `dependent: :destroy` on the entries -- leaving a shipment that
    # never left anywhere, which acceptance would then happily deliver.
    #
    # Refused rather than auto-cancelled: cancelling returns the goods to the
    # inventory being destroyed, which is a contradiction, and doing it silently
    # is the worst of the three.
    before_destroy :refuse_while_goods_are_in_transit, prepend: true
  end

  class_methods do
    def inventory_items_association(association_name)
      has_many association_name, dependent: :destroy

      alias_method :inventory_items, association_name if association_name != :inventory_items
    end

    # The positions of this inventory, under one name whichever table they are
    # in -- the same trick `inventory_items_association` plays for the entries.
    def positions_association(association_name)
      has_many association_name, dependent: :destroy

      alias_method :positions, association_name if association_name != :positions
    end
  end

  def ledger_attributes_for(_user)
    {}
  end

  NET_QUANTITY = "SUM(CASE WHEN entry_type = 0 THEN quantity ELSE -quantity END)"

  # Grouped by the position rather than by the labels on the entries. The labels
  # are still on the entries and still agree, but they are no longer what decides
  # which rows belong together -- which is the whole point of the position having
  # a row.
  #
  # Still driven from the entries, so a position holding none of them does not
  # appear here. `stock_item` resolves one directly and is where an emptied
  # position keeps answering.
  def current_stock
    position_scope
      .select(position_columns, "quality", "#{NET_QUANTITY} AS net_quantity")
      .group(position_group, :quality)
      .having("#{NET_QUANTITY} > 0")
      .order(position_name)
  end

  # Rolled up per stock position rather than per quality, matching how
  # withdrawals are checked against stock.
  def stock_positions
    position_scope
      .select(
        position_columns,
        "#{NET_QUANTITY} AS net_quantity",
        "MIN(quality) AS quality_min",
        "MAX(quality) AS quality_max",
        "COUNT(*) AS entries_count",
        "MAX(#{inventory_items.table_name}.created_at) AS last_entry_at"
      )
      .group(position_group)
      .order(position_name)
  end

  # Emptied-out positions still resolve, so a link to one keeps working once
  # everything has been withdrawn again -- and now a lookup rather than a scan of
  # every position in the inventory, because the slug is a column.
  def stock_item(slug)
    position = positions.find_by(slug:)

    return if position.blank?

    row = stock_positions.where(position_key => position.id).first || EmptyPosition.new(position)

    InventoryStockItem.new(row, inventory: self, reference_entry: reference_entry_for(row))
  end

  # How much of a hold everything in here fills, and how many positions could
  # not say. Bulk cargo counts itself; gear is counted per piece, so it only
  # answers once it points at something a catalogue has measured. What nothing
  # has measured is left out rather than guessed at, which makes the total a
  # floor and the count the distance it might be off by.
  def stock_volume
    stock_positions.each_with_object({total: 0.0, unmeasured: 0}) do |row, result|
      position = InventoryStockItem.new(row, inventory: self, reference_entry: reference_entry_for(row))
      volume = position.volume_scu

      if volume.nil?
        result[:unmeasured] += 1
      else
        result[:total] += volume
      end
    end
  end

  # A position nothing points at any more. `stock_positions` is grouped over the
  # entries, so it has no row there at all -- and a slug that still resolves has
  # to answer with zeros rather than a 404.
  EmptyPosition = Struct.new(:position) do
    def position_id = position.id

    def name = position.name

    def category = position.category

    def unit = position.unit

    def slug = position.slug

    def net_quantity = 0

    def quality_min = nil

    def quality_max = nil

    def entries_count = 0

    def last_entry_at = nil
  end

  def entries_for_stock_item(stock_item)
    inventory_items.where(position_key => stock_item.position_id)
  end

  # One row moves, and paper_trail files one version for it, because the position
  # is a record now rather than a label repeated across every entry.
  #
  # The entries' own name, category and unit move with it: the previous release
  # still reads them and the validations still check them, and they are dropped
  # in their own deploy once nothing does.
  #
  # Renaming a position onto an identity that already exists merges the two, the
  # same as it did when the identity was the group key -- the entries join the
  # other position and the emptied one goes.
  def update_stock_item(stock_item, attributes)
    target = attributes.symbolize_keys.slice(:name, :category, :unit)
    changed = InventoryStockItemChange.new(stock_item, target)

    return changed unless changed.valid?

    transaction { move_position(stock_item, changed) }

    touch

    changed
  end

  # Pending transfers are counted through the entries rather than through the
  # transfer's own columns, because either end of one may be in either ledger.
  def entries_in_transit
    inventory_items
      .joins(:inventory_transfer)
      .where(inventory_transfers: {aasm_state: "pending"})
  end

  # What this inventory has out on transfers nobody has answered. Summed per
  # unit, because SCU and pieces do not add up together.
  def in_transit_totals
    entries_in_transit.where(entry_type: :withdrawal).group(:unit).sum(:quantity)
      .transform_keys(&:to_s)
      .then { |totals| {scu: totals["scu"].to_f, units: totals["units"].to_f} }
  end

  def goods_in_transit?
    return false unless persisted?

    entries_in_transit.exists?
  end

  def destroy_stock_item(stock_item)
    in_transit = entries_for_stock_item(stock_item).joins(:inventory_transfer)
      .where(inventory_transfers: {aasm_state: "pending"})

    if in_transit.exists?
      errors.add(:base, :goods_in_transit,
        message: I18n.t("activerecord.errors.messages.position_goods_in_transit"))
      return false
    end

    transaction do
      entries_for_stock_item(stock_item).destroy_all
      positions.where(id: stock_item.position_id).destroy_all
    end

    touch
  end

  private def refuse_while_goods_are_in_transit
    return unless goods_in_transit?

    errors.add(:base, :goods_in_transit,
      message: I18n.t("activerecord.errors.messages.inventory_goods_in_transit"))
    throw(:abort)
  end

  private def move_position(stock_item, changed)
    position = positions.find_by(id: stock_item.position_id)

    return if position.blank?

    identity = {name: changed.name, category: changed.category, unit: changed.unit}
    destination = positions.find_by(identity)

    if destination.nil?
      position.update!(identity)
    elsif destination != position
      entries_for_stock_item(stock_item).update_all(position_key => destination.id)
      position.destroy
      position = destination
    end

    # The entries' own copies of the identity, which the previous release reads
    # and `withdrawal_does_not_exceed_stock` still checks. No versions for them:
    # the position's own version is the record of the move now, and one per
    # entry beside it would say the same thing N more times.
    inventory_items.where(position_key => position.id).update_all(changed.column_values)
  end

  # The newest entry that carries something worth showing: an uploaded image or
  # a reference to a game item the image can be borrowed from.
  private def reference_entry_for(row)
    entries = inventory_items
      .where(position_key => row.position_id)
      .order(created_at: :desc)

    entries.detect { |entry| entry.display_image.present? } || entries.first
  end

  private def position_scope
    inventory_items.joins(inventory_items.klass.position_association_name)
  end

  private def position_key
    inventory_items.klass.position_foreign_key
  end

  private def position_table
    inventory_items.klass.position_class.table_name
  end

  # Selected from the position and aliased to the names everything downstream
  # already reads, so the rollup rows keep the shape the views and the PORO
  # expect. The enum columns cast through the entry's own enums, which are the
  # same ones.
  private def position_columns
    [
      # Aliased to the entry's own foreign key column, not to `position_id`:
      # that name is an `alias_attribute` for this column on the entry, so a
      # select using it reads the unselected original and raises.
      "#{position_table}.id AS #{position_key}",
      "#{position_table}.name AS name",
      "#{position_table}.category AS category",
      "#{position_table}.unit AS unit",
      "#{position_table}.slug AS slug"
    ].join(", ")
  end

  private def position_group
    Arel.sql("#{position_table}.id, #{position_table}.name, #{position_table}.category, " \
             "#{position_table}.unit, #{position_table}.slug")
  end

  private def position_name
    Arel.sql("#{position_table}.name")
  end
end
