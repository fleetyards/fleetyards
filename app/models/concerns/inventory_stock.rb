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
  end

  class_methods do
    def inventory_items_association(association_name)
      has_many association_name, dependent: :destroy

      alias_method :inventory_items, association_name
    end
  end

  def ledger_attributes_for(_user)
    {}
  end

  def current_stock
    inventory_items
      .select(
        "name, category, unit, quality",
        "SUM(CASE WHEN entry_type = 0 THEN quantity ELSE -quantity END) AS net_quantity"
      )
      .group(:name, :category, :unit, :quality)
      .having("SUM(CASE WHEN entry_type = 0 THEN quantity ELSE -quantity END) > 0")
      .order(:name)
  end

  # Rolled up per stock position rather than per quality, matching how
  # withdrawals are checked against stock.
  def stock_positions
    inventory_items
      .select(
        "name, category, unit",
        "SUM(CASE WHEN entry_type = 0 THEN quantity ELSE -quantity END) AS net_quantity",
        "MIN(quality) AS quality_min",
        "MAX(quality) AS quality_max",
        "COUNT(*) AS entries_count",
        "MAX(created_at) AS last_entry_at"
      )
      .group(:name, :category, :unit)
      .order(:name)
  end

  # Emptied-out positions still resolve, so a link to one keeps working once
  # everything has been withdrawn again.
  def stock_item(slug)
    row = stock_positions.detect do |position|
      InventoryStockItem.slug_for(
        name: position.name, category: position.category, unit: position.unit
      ) == slug
    end

    return if row.blank?

    InventoryStockItem.new(
      row,
      inventory: self,
      reference_entry: reference_entry_for(row)
    )
  end

  def entries_for_stock_item(stock_item)
    inventory_items.where(
      name: stock_item.name, category: stock_item.category, unit: stock_item.unit
    )
  end

  # Every entry of a position moves together, so the ledger stays balanced. That
  # rules out saving them one by one: a withdrawal validated against the new
  # name before its deposits have been renamed would see no stock at all.
  def update_stock_item(stock_item, attributes)
    target = attributes.symbolize_keys.slice(:name, :category, :unit)
    changed = InventoryStockItemChange.new(stock_item, target)

    return changed unless changed.valid?

    entries_for_stock_item(stock_item).update_all(changed.column_values)
    touch

    changed
  end

  def destroy_stock_item(stock_item)
    entries_for_stock_item(stock_item).destroy_all
    touch
  end

  # The newest entry that carries something worth showing: an uploaded image or
  # a reference to a game item the image can be borrowed from.
  private def reference_entry_for(row)
    entries = inventory_items
      .where(name: row.name, category: row.category, unit: row.unit)
      .order(created_at: :desc)

    entries.detect { |entry| entry.display_image.present? } || entries.first
  end
end
