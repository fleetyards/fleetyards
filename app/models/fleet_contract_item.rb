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
# == Schema Information
#
# Table name: fleet_contract_items
#
#  id                :uuid             not null, primary key
#  category          :integer          default(0), not null
#  item_type         :string
#  name              :string           not null
#  position          :integer          default(0), not null
#  quality           :integer
#  quality_match     :integer          default(0), not null
#  quantity          :decimal(15, 2)   default(0.0), not null
#  unit              :integer          default(0), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  fleet_contract_id :uuid             not null
#  item_id           :uuid
#
# Indexes
#
#  index_fleet_contract_items_on_fleet_contract_id_and_position  (fleet_contract_id,position)
#  index_fleet_contract_items_on_identity                        (fleet_contract_id, lower((name)::text), category, unit) UNIQUE
#  index_fleet_contract_items_on_item_type_and_item_id           (item_type,item_id)
#
# Foreign Keys
#
#  fk_rails_...  (fleet_contract_id => fleet_contracts.id) ON DELETE => cascade
#
class FleetContractItem < ApplicationRecord
  belongs_to :fleet_contract, touch: true
  belongs_to :item, polymorphic: true, optional: true

  # How the grade on this line is read. `at_least` is the ordinary case; a
  # crafting job that wants exactly 500 and no better cannot say so otherwise.
  QUALITY_MATCHES = {at_least: 0, exact: 1}.freeze

  enum :category, ::InventoryLedgerEntry::CATEGORIES
  enum :unit, ::InventoryLedgerEntry::UNITS
  enum :quality_match, QUALITY_MATCHES, prefix: :quality

  validates :name, presence: true
  validates :quantity, numericality: {greater_than: 0}
  validates :quality,
    numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 1000},
    allow_nil: true
  validates :item_type, inclusion: {in: ::InventoryLedgerEntry::ITEM_TYPES}, allow_blank: true
  validates :item_type, presence: true, if: :item_id?
  validate :referenced_item_exists, if: :item_id?
  validate :unit_fits_category
  validate :identity_is_not_already_asked_for

  before_validation :set_name_from_item
  before_create :set_position

  scope :ordered, -> { order(:position, :created_at) }

  # A grade is a property of the goods, not of crafting -- the ledger records one
  # on every entry, and a haul can be asked for at a grade just as a crafting job
  # can. Nil is the permissive default and is what most lines carry.
  def required_quality
    quality
  end

  # Whether a deposit recorded at `grade` answers what this line asked for. A
  # line with no grade takes any, including the entries that carry none --
  # quality is optional on a ledger entry, and most rows have none.
  def quality_satisfied_by?(grade)
    required = required_quality
    return true if required.blank?
    return false if grade.blank?

    quality_exact? ? grade == required : grade >= required
  end

  # What `Contracts::Progress` groups deposits by. Downcased because a position
  # is resolved by `find_by(name:)` on a column with no case folding, and a
  # contract written as "Titanium" must count a deposit entered as "titanium".
  def position_identity
    [name.to_s.downcase, category, unit]
  end

  # Two lines with the same identity would both match the same deposits, so one
  # delivery would satisfy both and fulfil the contract at half the goods. The
  # unique index is the backstop; this is what makes it a readable 400.
  private def identity_is_not_already_asked_for
    return if fleet_contract.blank? || name.blank?

    twin = fleet_contract.fleet_contract_items
      .where.not(id: id)
      .where(category: category, unit: unit)
      .where("LOWER(name) = ?", name.to_s.downcase)

    return unless twin.exists?

    # Not a bare :taken -- "Name has already been taken" reads as though the
    # name alone were the conflict, when what collides is the whole identity the
    # ledger is matched on.
    errors.add(:name, :taken,
      message: I18n.t("activerecord.errors.messages.contract_item_already_asked_for"))
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

    allowed = ::InventoryLedgerEntry.units_for_category(category, referenced_item)
    return if allowed.blank? || allowed.include?(unit)

    errors.add(:unit, :inclusion)
  end

  # Reading `item` constantizes `item_type`, so the type has to be known to be
  # one of ours first -- the same gate `referenced_item_exists` applies.
  private def referenced_item
    return unless item_type.in?(::InventoryLedgerEntry::ITEM_TYPES)

    item
  end
end
