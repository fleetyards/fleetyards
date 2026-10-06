# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_squadron_requests
#
#  id                  :uuid             not null, primary key
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  fleet_membership_id :uuid             not null
#  fleet_squadron_id   :uuid             not null
#
# Indexes
#
#  index_fleet_squadron_requests_on_fleet_membership_id      (fleet_membership_id)
#  index_fleet_squadron_requests_on_squadron_and_membership  (fleet_squadron_id,fleet_membership_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_membership_id => fleet_memberships.id)
#  fk_rails_...  (fleet_squadron_id => fleet_squadrons.id)
#
# A member asking to be posted to a squadron. A team needs no request -- anyone
# in the fleet may join one -- so only an ordinary squadron takes them, and
# whoever manages its roster answers.
class FleetSquadronRequest < ApplicationRecord
  belongs_to :fleet_squadron
  belongs_to :fleet_membership

  validates :fleet_membership, uniqueness: {scope: :fleet_squadron_id, message: :already_requested}

  validate :membership_is_on_the_roster
  validate :squadron_is_not_a_team
  validate :not_already_a_member
  validate :no_other_exclusive_squadron

  # Leaving the fleet discards the membership rather than deleting it, so a
  # request from somebody who has since left is still a row.
  scope :pending, -> { joins(:fleet_membership).merge(FleetMembership.kept.accepted) }

  # Adds the member at the fleet's default rank and closes the request in one
  # go. The squadron membership runs its own checks, so a member who joined
  # another squadron since asking is refused here rather than posted twice.
  def accept!
    transaction do
      row = fleet_squadron.fleet_squadron_memberships.create!(fleet_membership:)
      destroy!
      row
    end
  end

  private def membership_is_on_the_roster
    return if fleet_squadron.blank? || fleet_membership.blank?
    return if fleet_membership.fleet_id == fleet_squadron.fleet_id && fleet_membership.kept? && fleet_membership.accepted?

    errors.add(:fleet_membership, :not_a_member)
  end

  private def squadron_is_not_a_team
    return if fleet_squadron.blank? || fleet_squadron.exclusive?

    errors.add(:fleet_squadron, :team)
  end

  private def not_already_a_member
    return if fleet_squadron.blank? || fleet_membership.blank?
    return unless fleet_squadron.fleet_squadron_memberships.exists?(fleet_membership_id:)

    errors.add(:fleet_squadron, :already_a_member)
  end

  # Asked up front rather than left to the answer: an officer who accepts would
  # only be told the member is in another squadron, which neither of them can
  # do anything about from there.
  private def no_other_exclusive_squadron
    return if fleet_squadron.blank? || fleet_membership.blank?

    held = fleet_membership.exclusive_squadron(except: fleet_squadron)
    return if held.blank?

    errors.add(:fleet_squadron, :exclusive_conflict, squadron: held.name)
  end
end
