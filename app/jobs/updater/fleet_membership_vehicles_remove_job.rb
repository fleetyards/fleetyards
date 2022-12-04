# frozen_string_literal: true

module Updater
  class FleetMembershipVehiclesRemoveJob < ::Updater::BaseJob
    def perform(fleet_membership_id:)
      fleet_membership = FleetMembership.find_by(id: fleet_membership_id)

      return if fleet_membership.blank?

      fleet_membership.remove_fleet_vehicles
    end
  end
end
