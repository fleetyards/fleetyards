# frozen_string_literal: true

# One stock position a contract asks for.
#
# The identity columns are the ledger's own. `InventoryLedgerEntry::
# POSITION_COLUMNS` is exactly `name`, `category`, `unit`, and that triple is
# what decides two entries belong to the same position -- so a line matches
# deposits by the same rule the deposits were grouped under. Matching on the
# item reference instead would miss a hand-typed deposit of the right goods,
# because the reference is optional on an entry.
#
# The enums, the unit/category pairing and the reference check are taken from
# `InventoryLedgerEntry` rather than re-typed, so a category added there cannot
# be asked for here without also being depositable.
class FleetContractItem < ApplicationRecord
  belongs_to :fleet_contract, touch: true
  belongs_to :item, polymorphic: true, optional: true

  enum :category, ::InventoryLedgerEntry::CATEGORIES
  enum :unit, ::InventoryLedgerEntry::UNITS

  validates :name, presence: true
  validates :quantity, numericality: {greater_than: 0}
  validates :min_quality,
    numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 1000},
    allow_nil: true
  validates :item_type, inclusion: {in: ::InventoryLedgerEntry::ITEM_TYPES}, allow_blank: true
  validates :item_type, presence: true, if: :item_id?
  validate :referenced_item_exists, if: :item_id?
  validate :unit_fits_category

  before_validation :set_name_from_item
  before_create :set_position

  scope :ordered, -> { order(:position, :created_at) }

  # Only a crafting contract can demand a grade. Asking for one on a haul would
  # silently stop counting deposits that came out of the fleet's own inventory
  # at whatever quality they were recorded with.
  def required_quality
    min_quality if fleet_contract&.crafting?
  end

  # What `Contracts::Progress` groups deposits by. Downcased because a position
  # is resolved by `find_by(name:)` on a column with no case folding, and a
  # contract written as "Titanium" must count a deposit entered as "titanium".
  def position_identity
    [name.to_s.downcase, category, unit]
  end

  private def set_name_from_item
    return if name.present?
    return if item.blank?

    self.name = item.name
  end

  private def set_position
    return if position.present? && position.positive?

    self.position = (fleet_contract&.fleet_contract_items&.maximum(:position) || 0) + 1
  end

  private def referenced_item_exists
    return unless item_type.in?(::InventoryLedgerEntry::ITEM_TYPES)

    errors.add(:item_id, :blank) if item.blank?
  end

  private def unit_fits_category
    return if category.blank? || unit.blank?

    allowed = ::InventoryLedgerEntry::UNITS_BY_CATEGORY[category]
    return if allowed.blank? || allowed.include?(unit)

    errors.add(:unit, :inclusion)
  end
end
