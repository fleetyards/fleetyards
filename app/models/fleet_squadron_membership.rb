# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_squadron_memberships
#
#  id                     :uuid             not null, primary key
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  fleet_membership_id    :uuid             not null
#  fleet_squadron_id      :uuid             not null
#  fleet_squadron_role_id :uuid             not null
#
# Indexes
#
#  index_fleet_squadron_memberships_on_fleet_membership_id      (fleet_membership_id)
#  index_fleet_squadron_memberships_on_fleet_squadron_role_id   (fleet_squadron_role_id)
#  index_fleet_squadron_memberships_on_squadron_and_membership  (fleet_squadron_id,fleet_membership_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_membership_id => fleet_memberships.id)
#  fk_rails_...  (fleet_squadron_id => fleet_squadrons.id)
#  fk_rails_...  (fleet_squadron_role_id => fleet_squadron_roles.id)
#
class FleetSquadronMembership < ApplicationRecord
  belongs_to :fleet_squadron, touch: true
  belongs_to :fleet_membership, touch: true
  belongs_to :fleet_squadron_role

  validates :fleet_membership_id, uniqueness: {scope: :fleet_squadron_id}

  validate :membership_belongs_to_same_fleet
  validate :exclusive_squadron_is_the_only_one
  validate :role_belongs_to_same_fleet
  validate :single_holder_role_is_free, if: :fleet_squadron_role_id_changed?

  before_validation :assign_default_role, on: :create

  # Somebody posted to the squadron directly has had their answer -- and once
  # they hold an ordinary squadron, every other one they asked is moot too.
  after_create :close_requests

  def self.ransackable_attributes(_auth_object = nil)
    %w[fleet_squadron_id fleet_membership_id fleet_squadron_role_id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[fleet_squadron fleet_membership fleet_squadron_role]
  end

  # A squadron is a sub-group of one fleet, so a membership from another fleet
  # is not "not allowed here" -- it is a row that would let one fleet's roster
  # leak into another's vehicle list and stats.
  private def membership_belongs_to_same_fleet
    return if fleet_squadron.blank? || fleet_membership.blank?
    return if fleet_squadron.fleet_id == fleet_membership.fleet_id

    errors.add(:fleet_membership, :not_a_member)
  end

  # A member holds at most one ordinary squadron in a fleet. Teams sit outside
  # the rule on both sides -- joining one is never refused, and being in one
  # never blocks anything. The check is here rather than on the squadron
  # because this is the row that creates the conflict, and refusing it names
  # the squadron the member is already in, which is the only useful thing to
  # say about a join that cannot happen.
  private def exclusive_squadron_is_the_only_one
    return if fleet_squadron.blank? || fleet_membership.blank?
    return unless fleet_squadron.exclusive?

    # Save holds this lock through validation and insertion. Concurrent joins
    # for the same member must recheck after the preceding join commits.
    FleetMembership.where(id: fleet_membership_id).lock.take

    held = fleet_membership.exclusive_squadron(except: fleet_squadron)

    return if held.blank?

    errors.add(:fleet_squadron, :exclusive_conflict, squadron: held.name)
  end

  private def close_requests
    requests = FleetSquadronRequest.where(fleet_membership_id:)
    requests = requests.where(fleet_squadron_id:) unless fleet_squadron.exclusive?
    requests.delete_all
  end

  private def assign_default_role
    return if fleet_squadron_role.present? || fleet_squadron.blank?

    self.fleet_squadron_role = FleetSquadronRole.default_for(fleet_squadron.fleet)
  end

  private def role_belongs_to_same_fleet
    return if fleet_squadron.blank? || fleet_squadron_role.blank?
    return if fleet_squadron.fleet_id == fleet_squadron_role.fleet_id

    errors.add(:fleet_squadron_role, :not_in_fleet)
  end

  # One Leader and one Co-Leader per squadron. Nothing in the row itself says
  # which slot a role is, so a unique index cannot hold the rule; the squadron
  # lock serialises two promotions into the same slot instead. Only the current
  # roster counts: leaving the fleet discards the membership but keeps this
  # row, and a Leader who left must not hold the slot nobody can see.
  private def single_holder_role_is_free
    return if fleet_squadron.blank? || fleet_squadron_role.blank?
    return unless fleet_squadron_role.single_holder?

    FleetSquadron.where(id: fleet_squadron_id).lock.take

    held = FleetSquadronMembership
      .joins(:fleet_membership)
      .merge(FleetMembership.kept.accepted)
      .where(fleet_squadron_id:, fleet_squadron_role_id:)
      .where.not(id:)
      .exists?

    return unless held

    errors.add(:fleet_squadron_role, :single_holder_taken, role: fleet_squadron_role.name)
  end
end
