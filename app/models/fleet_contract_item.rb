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
  # A line may ask for a crafted part: the recipe, and the grades it wants.
  # Unlike a part someone holds, a request may leave a slot open.
  include CraftedPart

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
  # Kept on a line of any contract, so switching how a contract pays and back
  # does not lose the rates; only a per-unit contract has to have them.
  validates :reward_rate, numericality: {greater_than: 0}, allow_nil: true
  validates :reward_rate, presence: true, if: -> { fleet_contract&.reward_per_unit? }
  validates :item_type, inclusion: {in: ::InventoryLedgerEntry::ITEM_TYPES}, allow_blank: true
  validates :item_type, presence: true, if: :item_id?
  validate :referenced_item_exists, if: :item_id?
  validate :unit_fits_category
  validate :identity_is_not_already_asked_for
  validate :crafted_from_a_recipe_for_the_item, if: :crafting_written?

  before_validation :set_name_from_item
  before_validation :drop_grades_without_a_recipe
  before_create :set_position

  scope :ordered, -> { order(:position, :created_at) }

  # A grade is a property of the goods, not of crafting -- the ledger records one
  # on every entry, and a haul can be asked for at a grade just as a crafting job
  # can. Nil is the permissive default and is what most lines carry.
  def required_quality
    quality
  end

  # Whether a delivered lot answers what this line asked for. A crafted line
  # takes only parts crafted from its recipe, each named grade met under the
  # line's match rule. A plain line takes crafted parts too: they are that part.
  def satisfied_by?(grade:, crafted_blueprint_id: nil, crafted_qualities: nil)
    return quality_satisfied_by?(grade) unless crafted?
    return false unless crafted_blueprint_id == self.crafted_blueprint_id

    (self.crafted_qualities || {}).all? do |position, required|
      held = (crafted_qualities || {})[position.to_s]
      next false if held.nil?

      quality_exact? ? held == required : held >= required
    end
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

  # What `counted` SCU or units delivered against this line earn on a per-unit
  # contract.
  def reward_for(counted)
    (reward_rate || 0).to_d * counted
  end

  # What `Contracts::Progress` groups deposits by. Downcased because a position
  # is resolved by `find_by(name:)` on a column with no case folding, and a
  # contract written as "Titanium" must count a deposit entered as "titanium".
  def position_identity
    [name.to_s.downcase, category, unit]
  end

  # What makes two lines the same request: the position, and -- for a crafted
  # part -- the recipe, the grades and how they are read. The unique index
  # says the same thing.
  def request_identity
    [
      *position_identity,
      crafted_blueprint_id,
      (crafted_qualities || {}).transform_keys(&:to_s).sort.to_h,
      crafted? ? quality_match : nil
    ]
  end

  # Two lines asking for the same thing the same way would compete for every
  # delivery, and the contract could not say which was meant. The unique index
  # is the backstop; this is what makes it a readable 400.
  private def identity_is_not_already_asked_for
    return if fleet_contract.blank? || name.blank?

    twins = fleet_contract.fleet_contract_items
      .where.not(id: id)
      .where(category: category, unit: unit, crafted_blueprint_id: crafted_blueprint_id)
      .where("LOWER(name) = ?", name.to_s.downcase)
      .where("COALESCE(crafted_qualities, '{}'::jsonb) = ?::jsonb", (crafted_qualities || {}).to_json)
    twins = twins.where(quality_match: quality_match) if crafted?

    return unless twins.exists?

    # Not a bare :taken -- "Name has already been taken" reads as though the
    # name alone were the conflict, when what collides is the whole identity the
    # ledger is matched on.
    errors.add(:name, :taken,
      message: I18n.t("activerecord.errors.messages.contract_item_already_asked_for"))
  end

  private def crafted_grades_required?
    false
  end

  # A line that stops asking for a crafted part stops asking for its grades.
  # Sent as null, the grades never reach the model -- a permitted hash drops
  # an explicit null -- so clearing the recipe has to clear them here.
  private def drop_grades_without_a_recipe
    self.crafted_qualities = nil if crafted_blueprint_id.blank?
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
