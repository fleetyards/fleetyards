# frozen_string_literal: true

# A stock position inside an inventory: every ledger entry sharing a name,
# category and unit, rolled up. Stock has no row of its own in the database,
# so it is addressed by a slug derived from those three values.
class InventoryStockItem
  attr_reader :name, :category, :unit, :net_quantity, :quality_min, :quality_max,
    :entries_count, :last_entry_at, :inventory, :reference_entry

  def self.slug_for(name:, category:, unit:)
    [name.to_s.parameterize.presence || "item", category, unit].join("--")
  end

  def initialize(row, inventory: nil, reference_entry: nil)
    @name = row.name
    @category = row.category
    @unit = row.unit
    @net_quantity = row.net_quantity
    @quality_min = row.quality_min
    @quality_max = row.quality_max
    @entries_count = row.entries_count
    @last_entry_at = row.last_entry_at
    @inventory = inventory
    @reference_entry = reference_entry
  end

  def slug
    self.class.slug_for(name: name, category: category, unit: unit)
  end

  def item
    reference_entry&.item
  end

  def item_available?
    reference_entry.nil? || reference_entry.item_available?
  end

  def image
    reference_entry&.display_image
  end
end
