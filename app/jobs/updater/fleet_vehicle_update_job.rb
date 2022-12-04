# frozen_string_literal: true

module Updater
  class FleetVehicleUpdateJob < ::Updater::BaseJob
    def perform(vehicle_id:)
      vehicle = Vehicle.find_by(id: vehicle_id)

      return if vehicle.blank?

      vehicle.update_fleet_vehicle
    end
  end
end
