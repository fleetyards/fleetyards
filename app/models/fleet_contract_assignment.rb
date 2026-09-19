# frozen_string_literal: true

# Somebody working a contract: its `lead`, or `crew` the lead took on.
#
# The lead is created straight into `accepted` -- claiming an open contract is
# not a request anybody has to answer. Everyone else lands in `requested` and
# waits for the lead, or for a member holding `fleet:contracts:manage`, who has
# to be able to unstick a contract whose lead has gone quiet.
#
# One accepted lead per contract is a partial unique index rather than a
# validation, because two members claiming the same contract at the same moment
# both read no lead and both write one.
# == Schema Information
#
# Table name: fleet_contract_assignments
#
#  id                :uuid             not null, primary key
#  aasm_state        :string           default("requested"), not null
#  accepted_at       :datetime
#  declined_at       :datetime
#  removed_at        :datetime
#  requested_at      :datetime
#  role              :integer          default(1), not null
#  withdrawn_at      :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  approved_by_id    :uuid
#  fleet_contract_id :uuid             not null
#  user_id           :uuid             not null
#
# Indexes
#
#  idx_on_fleet_contract_id_user_id_cd14b5f8cd             (fleet_contract_id,user_id) UNIQUE
#  index_fleet_contract_assignments_on_accepted_lead       (fleet_contract_id) UNIQUE WHERE ((role = 0) AND ((aasm_state)::text = 'accepted'::text))
#  index_fleet_contract_assignments_on_approved_by_id      (approved_by_id)
#  index_fleet_contract_assignments_on_contract_and_state  (fleet_contract_id,aasm_state)
#  index_fleet_contract_assignments_on_user_id             (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (approved_by_id => users.id) ON DELETE => nullify
#  fk_rails_...  (fleet_contract_id => fleet_contracts.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
class FleetContractAssignment < ApplicationRecord
  include AASM

  ROLES = {lead: 0, crew: 1}.freeze

  belongs_to :fleet_contract, touch: true
  belongs_to :user
  belongs_to :approved_by, class_name: "User", optional: true

  enum :role, ROLES

  validates :user_id, uniqueness: {scope: :fleet_contract_id}
  validate :crew_limit_not_exceeded, if: -> { crew? && accepted? }

  aasm timestamps: true, whiny_transitions: false do
    state :requested, initial: true
    state :accepted
    state :declined
    state :withdrawn
    state :removed

    event :accept do
      transitions from: :requested, to: :accepted
    end

    event :decline do
      transitions from: :requested, to: :declined
    end

    # The contractor leaving of their own accord.
    event :withdraw do
      transitions from: [:requested, :accepted], to: :withdrawn
    end

    # The lead or an officer taking them off it.
    event :remove do
      transitions from: [:requested, :accepted], to: :removed
    end
  end

  # `requested_at` is what an approval queue sorts by, and aasm only stamps a
  # state it transitions *into* -- nothing transitions into the initial one.
  before_create :stamp_requested_at

  def self.ransackable_attributes(_auth_object = nil)
    %w[fleet_contract_id user_id role aasm_state created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[fleet_contract user]
  end

  # The crew limit is a check-then-insert, so two accepts on *different* rows
  # both read the same count and both write. The contract row is what orders
  # them: with it held, the second re-reads what the first committed.
  #
  # The same reasoning as `FleetContract#claim_by`, and the reason the limit
  # cannot simply be a unique index -- it counts rows rather than forbidding a
  # second one.
  def approve!(actor)
    fleet_contract.with_lock do
      self.approved_by = actor

      accept!
    end
  end

  private def stamp_requested_at
    self.requested_at ||= Time.current
  end

  # Counted over the other rows, not including this one: a record being accepted
  # is not yet accepted in the database, and counting itself would refuse the
  # last place on every contract.
  private def crew_limit_not_exceeded
    limit = fleet_contract&.crew_limit
    return if limit.blank?

    taken = fleet_contract.fleet_contract_assignments
      .accepted.crew.where.not(id: id).count

    return if taken < limit

    errors.add(:base, :crew_limit_reached)
  end
end
