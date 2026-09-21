# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_squadron_memberships
#
#  id                  :uuid             not null, primary key
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  fleet_membership_id :uuid             not null
#  fleet_squadron_id   :uuid             not null
#
# Indexes
#
#  index_fleet_squadron_memberships_on_fleet_membership_id      (fleet_membership_id)
#  index_fleet_squadron_memberships_on_squadron_and_membership  (fleet_squadron_id,fleet_membership_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_membership_id => fleet_memberships.id)
#  fk_rails_...  (fleet_squadron_id => fleet_squadrons.id)
#
class FleetSquadronMembership < ApplicationRecord
  belongs_to :fleet_squadron, touch: true
  belongs_to :fleet_membership

  validates :fleet_membership_id, uniqueness: {scope: :fleet_squadron_id}

  validate :membership_belongs_to_same_fleet

  def self.ransackable_attributes(_auth_object = nil)
    %w[fleet_squadron_id fleet_membership_id created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[fleet_squadron fleet_membership]
  end

  # A squadron is a sub-group of one fleet, so a membership from another fleet
  # is not "not allowed here" -- it is a row that would let one fleet's roster
  # leak into another's vehicle list and stats.
  private def membership_belongs_to_same_fleet
    return if fleet_squadron.blank? || fleet_membership.blank?
    return if fleet_squadron.fleet_id == fleet_membership.fleet_id

    errors.add(:fleet_membership, :not_a_member)
  end
end
