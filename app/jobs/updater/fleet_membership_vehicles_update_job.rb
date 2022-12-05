# frozen_string_literal: true

module Updater
  class FleetMembershipVehiclesUpdateJob < ::Updater::BaseJob
    sidekiq_options lock: :until_executed, on_conflict: :reject

    def perform(fleet_membership_id)
      fleet_membership = FleetMembership.find_by(id: fleet_membership_id)

      return if fleet_membership.blank?

      fleet_membership.update_fleet_vehicles
    end
  end
end
