# frozen_string_literal: true

# Validates a rename/recategorisation of a whole stock position before it is
# applied to every entry at once. The entries themselves cannot carry these
# checks: they are updated in bulk, which skips record validations, and running
# them per entry would fail on withdrawals half-way through the change.
class InventoryStockItemChange
  include ActiveModel::Model

  attr_accessor :name, :category, :unit

  # Every catalogue record the position's entries point at, with a nil for each
  # entry that points at nothing. Read rather than written: the rename cannot
  # move them, but they decide which units the position may be recorded in --
  # a counted commodity may be pieces, and a free-text line may not.
  #
  # All of them, not the reference entry's one: `move_position` writes the unit
  # to every entry with `update_all`, which skips validation, so authorising
  # the move from a single entry leaves the others holding a pairing their own
  # validator forbids.
  attr_reader :items

  validates :name, presence: true
  validate :category_is_known
  validate :unit_is_known
  validate :unit_fits_category

  def initialize(stock_item, attributes = {}, items: nil)
    @name = attributes.fetch(:name, stock_item.name).to_s.strip
    @category = attributes.fetch(:category, stock_item.category).to_s
    @unit = attributes.fetch(:unit, stock_item.unit).to_s
    # The reference entry's item is the fallback for a caller that has no
    # inventory to ask -- the console and the tests.
    @items = items.presence || [stock_item.item]
  end

  # Enum values, not names: the update runs as a single UPDATE, which writes the
  # columns raw. (`Model.units` is no help here — the "units" enum value shadows
  # the mapping with a scope of the same name.)
  def column_values
    {
      name: name,
      category: InventoryLedgerEntry::CATEGORIES[category.to_sym],
      unit: InventoryLedgerEntry::UNITS[unit.to_sym],
      updated_at: Time.current
    }
  end

  private def category_is_known
    return if InventoryLedgerEntry::CATEGORIES.key?(category.to_sym)

    errors.add(:category, :inclusion)
  end

  private def unit_is_known
    return if InventoryLedgerEntry::UNITS.key?(unit.to_sym)

    errors.add(:unit, :inclusion)
  end

  private def unit_fits_category
    return if errors.any?

    # What every entry in the position can accept, which is the intersection:
    # one free-text line is enough to hold the whole position to SCU.
    allowed = items.map { |entry_item| InventoryLedgerEntry.units_for_category(category, entry_item) }
      .reduce(:&).to_a

    return if allowed.include?(unit)

    errors.add(:unit, :inclusion, message: "must be #{allowed.join(" or ")} for #{category} entries")
  end
end
