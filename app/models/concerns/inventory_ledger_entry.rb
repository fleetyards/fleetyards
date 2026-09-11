# frozen_string_literal: true

module InventoryLedgerEntry
  extend ActiveSupport::Concern

  CATEGORIES = {
    commodity: 0,
    component: 1,
    weapon: 2,
    equipment: 3,
    ammunition: 4,
    consumable: 5,
    other: 6
  }.freeze

  # item_type reaches us from the client, and a polymorphic belongs_to would
  # happily point an entry at any model in the app — including records the
  # signed-in user cannot see, whose name would then be copied onto the entry.
  ITEM_TYPES = %w[Commodity Component Equipment].freeze

  UNITS = {scu: 0, units: 1}.freeze

  # Only bulk cargo is measured in SCU; gear is counted per piece. "other" is
  # the escape hatch for anything that does not fit either habit.
  UNITS_BY_CATEGORY = {
    "commodity" => ["scu"],
    "component" => ["units"],
    "weapon" => ["units"],
    "equipment" => ["units"],
    "ammunition" => ["units"],
    "consumable" => ["units"],
    "other" => UNITS.keys.map(&:to_s)
  }.freeze

  ENTRY_TYPES = {deposit: 0, withdrawal: 1}.freeze

  # What makes two entries the same stock position, and so the columns no single
  # entry may move on its own -- `InventoryStock#update_stock_item` moves all of
  # them together or none.
  POSITION_COLUMNS = %w[name category unit].freeze

  DEFAULT_SORTING_PARAMS = ["created_at desc"]
  ALLOWED_SORTING_PARAMS = [
    "name asc", "name desc",
    "quantity asc", "quantity desc",
    "category asc", "category desc",
    "entryType asc", "entryType desc",
    "createdAt asc", "createdAt desc"
  ]

  included do
    belongs_to :item, polymorphic: true, optional: true

    has_one_attached :image

    enum :category, CATEGORIES
    enum :unit, UNITS
    enum :entry_type, ENTRY_TYPES

    validates :name, presence: true
    validates :image, no_vector_image: true
    validates :quantity, numericality: {greater_than: 0}
    validates :quality, numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 1000}, allow_nil: true
    validates :item_type, inclusion: {in: ITEM_TYPES}, allow_blank: true
    validates :item_type, presence: true, if: :item_id?
    validate :withdrawal_does_not_exceed_stock, if: :withdrawal?
    validate :referenced_item_exists, if: :item_id?
    # Existing rows predate the pairing, so only entries that touch either side
    # of it have to satisfy it.
    validate :unit_fits_category, if: -> {
      new_record? || will_save_change_to_unit? || will_save_change_to_category?
    }

    # A position is nothing but the entries that share a name, category and
    # unit, so changing one of those on a single entry moves it out of the
    # position it was in -- and any withdrawals left behind land in a group with
    # no deposits, at a negative net that `current_stock` hides. An entry that
    # is alone in its position *is* the position, so it may move itself.
    # Anything else goes through `InventoryStock#update_stock_item`, which moves
    # every entry at once.
    validate :position_is_moved_as_a_whole, if: -> {
      persisted? && POSITION_COLUMNS.any? { |column| will_save_change_to_attribute?(column) }
    }

    before_validation :set_name_from_item

    before_save :assign_position
  end

  class_methods do
    def inventory_association(association_name)
      belongs_to association_name, touch: true

      # Aliasing a name to itself makes the generated reader call itself, so the
      # canonical association is left alone.
      if association_name != :inventory
        alias_method :inventory, association_name
        alias_attribute :inventory_id, :"#{association_name}_id"
      end

      @inventory_foreign_key = :"#{association_name}_id"
    end

    def inventory_foreign_key
      @inventory_foreign_key
    end

    # The position an entry belongs to. Optional for now: the previous release
    # is still inserting entries that know nothing about it while the migration
    # runs, so the column cannot be `null: false` until its own deploy.
    def position_association(association_name)
      belongs_to association_name, optional: true

      if association_name != :position
        # Both directions: `assign_position` writes it, everything else reads it.
        alias_method :position, association_name
        alias_method :"position=", :"#{association_name}="
        alias_attribute :position_id, :"#{association_name}_id"
      end

      @position_association_name = association_name
      @position_foreign_key = :"#{association_name}_id"
    end

    def position_foreign_key
      @position_foreign_key
    end

    def position_association_name
      @position_association_name
    end

    def position_class
      reflect_on_association(position_association_name).klass
    end

    def units_for_category(category)
      UNITS_BY_CATEGORY.fetch(category.to_s, UNITS.keys.map(&:to_s))
    end

    def net_quantity_for(inventory_id, name, category, unit)
      where(inventory_foreign_key => inventory_id, :name => name, :category => category, :unit => unit)
        .sum("CASE WHEN entry_type = 0 THEN quantity ELSE -quantity END")
    end
  end

  # Falls back to the referenced game item's artwork, so an entry pointing at a
  # component looks like that component without anyone uploading a picture.
  def display_image
    return image if image.attached?
    return unless referenced_item?
    return unless item.respond_to?(:store_image) && item.store_image.attached?

    item.store_image
  end

  # Reading `item` constantizes item_type, so both the name default and the
  # existence check have to wait until the type is known to be one of ours.
  def referenced_item?
    item_type.in?(ITEM_TYPES) && item.present?
  end

  # Entries are never broken by a patch: the row they point at stays, so the
  # name, the image and the stock they carry keep resolving. What changes is
  # that the pickers stop offering the item, and this is what says so, rather
  # than leaving a player to work out why they cannot record more of something
  # they are holding.
  #
  # Asked of the build describing the item rather than of the `version` column
  # on its row. The column names whichever build was loaded last, across every
  # environment, so a ptu load moves it off the live build for every row at
  # once and leaves every live entry claiming to be missing. Measured on the
  # first real ptu load: as a live request 0 of 10 entries reported available,
  # as a ptu request 10 of 10, with each item's live build row sitting there
  # untouched. The build row is the same thing `current_version` resolves
  # against for all three catalogues an entry can name.
  #
  # Entries naming a thing without pointing at one -- most of them -- have
  # nothing to be missing from.
  def item_available?
    return true unless referenced_item?
    return true unless item.respond_to?(:build)

    item.build.present?
  end

  # What one piece costs a cargo grid, in SCU. Bulk cargo is already counted in
  # SCU, so only gear needs the lookup, and only gear the entry actually points
  # at can answer it — a hand-typed "Medpen" has no volume anywhere.
  #
  # The two catalogues keep the figure in different shapes because they were
  # imported years apart: Equipment stores SCU on the row, Component keeps the
  # game's microSCU inside the occupancy blob. One microSCU is what CIG leaves
  # on a record nobody measured, so it reads as unknown rather than as nothing.
  def item_volume
    return unless referenced_item?

    case item
    when ::Equipment then item.volume&.to_f
    when ::Component then component_item_volume
    end&.then { |volume| volume if volume.positive? }
  end

  private def component_item_volume
    micro_scu = item.inventory_consumption.try(:[], "micro_scu").to_f

    micro_scu / 1_000_000 if micro_scu > 1.0
  end

  private def set_name_from_item
    return if name.present?
    return unless referenced_item?

    self.name = item.name
  end

  private def referenced_item_exists
    return unless item_type.in?(ITEM_TYPES)

    errors.add(:item_id, :blank) if item.blank?
  end

  # Resolved on the entry rather than at each call site, because there are five
  # of them -- three controllers, the CSV import, and the fleet restore -- plus
  # the console and the factories, and every one already carries the name,
  # category and unit that decide which position this is.
  #
  # `before_save` rather than `before_validation`: an entry that fails
  # validation must not leave a position behind.
  private def assign_position
    return if inventory.blank?
    return if position_id.present? && POSITION_COLUMNS.none? { |column| will_save_change_to_attribute?(column) }

    self.position = resolve_position
  end

  private def resolve_position
    identity = {name:, category:, unit:}
    scope = inventory.positions

    scope.find_by(identity) || create_position(scope, identity)
  end

  # The savepoint is what keeps the caller's transaction usable when a concurrent
  # deposit of the same position wins the race -- the shape `Inventory.create_for`
  # already uses for provisioning an inventory.
  #
  # Resolving happens before `withdrawal_does_not_exceed_stock` takes its lock on
  # the inventory, and that order is the same on every path, which is what keeps a
  # deposit and a withdrawal from deadlocking against each other.
  private def create_position(scope, identity)
    self.class.transaction(requires_new: true) { scope.create!(identity) }
  rescue ActiveRecord::RecordNotUnique
    scope.find_by!(identity)
  end

  private def position_is_moved_as_a_whole
    return unless position_shared?

    POSITION_COLUMNS.each do |column|
      next unless will_save_change_to_attribute?(column)

      errors.add(column, :position_shared,
        message: "cannot move one entry out of a position -- update the whole position instead")
    end
  end

  # Against the values still in the database, not the ones being written: the
  # position an entry is leaving is the one it is still grouped under.
  private def position_shared?
    self.class
      .where(self.class.inventory_foreign_key => inventory_id)
      .where(
        name: attribute_in_database("name"),
        category: attribute_in_database("category"),
        unit: attribute_in_database("unit")
      )
      .where.not(id: id)
      .exists?
  end

  private def unit_fits_category
    return if category.blank? || unit.blank?

    allowed = self.class.units_for_category(category)
    return if unit.in?(allowed)

    errors.add(:unit, :inclusion, message: "must be #{allowed.join(" or ")} for #{category} entries")
  end

  private def withdrawal_does_not_exceed_stock
    # Stock is derived from the entries rather than stored, so two withdrawals
    # racing each other would both read the same balance and both pass. Taking
    # the inventory row for the rest of the surrounding save transaction makes
    # the second one wait and re-read what the first left behind.
    inventory&.lock! if inventory&.persisted?

    current = self.class.net_quantity_for(inventory_id, name, category, unit)

    if quantity > current
      errors.add(:quantity, :insufficient_stock, message: "exceeds current stock (#{current})")
    end
  end
end
