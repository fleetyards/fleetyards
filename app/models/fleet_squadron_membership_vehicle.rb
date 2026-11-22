# frozen_string_literal: true

# One of a member's ships they give a squadron by name. With the "picked"
# choice these are the squadron's whole share of the member's ships; with a
# hangar group they are added to it, which is where a ship an officer asked for
# and the member agreed to ends up.
class FleetSquadronMembershipVehicle < ApplicationRecord
  belongs_to :fleet_squadron_membership, touch: true
  belongs_to :vehicle

  validates :vehicle_id, uniqueness: {scope: :fleet_squadron_membership_id}

  validate :vehicle_belongs_to_the_member
  validate :vehicle_fits_the_role, on: :create

  private def vehicle_belongs_to_the_member
    return if vehicle.blank? || fleet_squadron_membership.blank?
    return if vehicle.user_id == fleet_squadron_membership.fleet_membership&.user_id

    errors.add(:vehicle, :not_owned)
  end

  # A ship picked now has to fit the squadron's role; one picked before the
  # lead narrowed it keeps its row.
  private def vehicle_fits_the_role
    squadron = fleet_squadron_membership&.fleet_squadron
    return if vehicle.blank? || squadron.blank?

    errors.add(:vehicle, :outside_role) unless squadron.fits_role?(vehicle.model)
  end
end
