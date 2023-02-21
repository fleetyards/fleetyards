# frozen_string_literal: true

module DataMigrate
  class PurchasedToWantedJob < ApplicationJob
    def perform(vehicle_id)
      vehicle = Vehicle.find(vehicle_id)

      vehicle.update(wanted: !vehicle.purchased?)
    end
  end
end
