# frozen_string_literal: true

# One stock position of an inventory, with the quantities rolled up from its
# entries. The identity is a row now -- `InventoryPosition` -- and this is the
# view of it the API renders: the row's own columns beside sums that are not
# stored anywhere.
class InventoryStockItem
  attr_reader :position_id, :name, :category, :unit, :slug, :net_quantity,
    :quality_min, :quality_max, :entries_count, :last_entry_at, :inventory,
    :reference_entry

  # The address a position gets, still derived here rather than on the model so
  # there is one definition of it. `StockPosition` calls this to fill its column,
  # and three published endpoints take the result as a path segment.
  def self.slug_for(name:, category:, unit:)
    [name.to_s.parameterize.presence || "item", category, unit].join("--")
  end

  def initialize(row, inventory: nil, reference_entry: nil)
    @position_id = row.position_id
    @name = row.name
    @category = row.category
    @unit = row.unit
    @slug = row.slug
    @net_quantity = row.net_quantity
    @quality_min = row.quality_min
    @quality_max = row.quality_max
    @entries_count = row.entries_count
    @last_entry_at = row.last_entry_at
    @inventory = inventory
    @reference_entry = reference_entry
  end

  def item
    reference_entry&.item
  end

  def item_available?
    reference_entry.nil? || reference_entry.item_available?
  end

  # How much of a hold this position fills. Bulk cargo says so itself; gear is
  # counted per piece, so it only answers once the position points at something
  # the catalogues have measured.
  def volume_scu
    return net_quantity.to_f if unit == "scu"

    per_piece = reference_entry&.item_volume

    per_piece && (per_piece * net_quantity.to_f)
  end

  def image
    reference_entry&.display_image
  end
end
