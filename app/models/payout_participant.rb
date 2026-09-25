# frozen_string_literal: true

# == Schema Information
#
# Table name: payout_participants
#
#  id               :uuid             not null, primary key
#  name             :string
#  weight           :decimal(5, 2)    default(1.0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  added_by_id      :uuid
#  fleet_id         :uuid
#  payout_ledger_id :uuid             not null
#  user_id          :uuid
#
# Indexes
#
#  index_payout_participants_on_fleet_id              (fleet_id)
#  index_payout_participants_on_payout_ledger_id      (payout_ledger_id)
#  index_payout_participants_unique_fleet_per_ledger  (payout_ledger_id,fleet_id) UNIQUE WHERE (fleet_id IS NOT NULL)
#  index_payout_participants_unique_user_per_ledger   (payout_ledger_id,user_id) UNIQUE WHERE (user_id IS NOT NULL)
#
# Foreign Keys
#
#  fk_rails_...  (added_by_id => users.id)
#  fk_rails_...  (fleet_id => fleets.id)
#  fk_rails_...  (payout_ledger_id => payout_ledgers.id)
#  fk_rails_...  (user_id => users.id)
#
class PayoutParticipant < ApplicationRecord
  belongs_to :payout_ledger, touch: true
  belongs_to :user, optional: true
  # A contract's payer is the fleet, and a free-text guest standing in for it
  # could not be authorised, notified or linked.
  belongs_to :fleet, optional: true
  belongs_to :added_by, class_name: "User", optional: true

  has_many :payout_entries, dependent: :restrict_with_error

  # Someone on the tour without a FleetYards account is named rather than
  # linked, which is the only way the payout list can account for them at all.
  # SupporterContribution carries the same pair for the same reason.
  validates :name, presence: true, if: :guest?
  validates :user_id, uniqueness: {scope: :payout_ledger_id}, allow_nil: true
  validates :fleet_id, uniqueness: {scope: :payout_ledger_id}, allow_nil: true
  validate :one_party
  # Strictly positive, not merely non-negative. A weight of zero on every
  # participant would leave the profit divided by nothing, and the shares would
  # sum to less than it -- which breaks the one invariant the transfer list is
  # built on. Somebody who is to receive nothing is not a participant with a
  # zero weight, they are off the list, and removing them has its own rule.
  validates :weight, numericality: {greater_than: 0, less_than_or_equal_to: 999.99}
  validate :ledger_is_open, on: :create
  validate :ledger_is_open_for_weight, on: :update

  before_destroy :check_for_entries, prepend: true
  before_destroy :ledger_must_be_open, prepend: true

  # Every participant's page is showing figures derived from this row, so a
  # change here has to reach all of them, not only the tab that made it.
  after_commit :broadcast_ledger_change

  def guest? = user_id.blank? && fleet_id.blank?

  def display_name
    user&.username.presence || fleet&.name.presence || name
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[payout_ledger_id user_id fleet_id name weight created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[payout_ledger user fleet payout_entries]
  end

  private def one_party
    return unless user_id.present? && fleet_id.present?

    errors.add(:base, :one_party)
  end

  # Removing someone re-divides the profit across everyone who is left, so a
  # participant who has already recorded money cannot just disappear -- their
  # entries would be orphaned and every other balance would silently move.
  # Adding or removing someone changes the head count the profit is divided by,
  # so both take the same lock settling does -- a participant joining while the
  # transfers are being computed would otherwise be left out of a list that can
  # no longer be changed.
  private def ledger_is_open
    return if payout_ledger.blank?
    return if payout_ledger.open_for_edits?

    errors.add(:base, :ledger_settled)
  end

  # A weight is what the profit is divided by, so moving one after the transfers
  # were frozen would leave the settled payout list describing a split that no
  # longer exists -- the same reason an entry cannot move, and it takes the same
  # lock for the same race. Guarded on the weight alone so an unrelated save
  # does not lock the ledger row.
  private def ledger_is_open_for_weight
    return unless will_save_change_to_weight?
    return if payout_ledger.blank?
    return if payout_ledger.open_for_edits?

    errors.add(:base, :ledger_settled)
  end

  private def ledger_must_be_open
    return if payout_ledger.blank?
    return if payout_ledger.open_for_edits?

    errors.add(:base, :ledger_settled)
    throw :abort
  end

  private def check_for_entries
    return if payout_entries.empty?

    errors.add(:base, :has_entries)
    throw :abort
  end

  private def broadcast_ledger_change
    payout_ledger&.broadcast_change
  end
end
