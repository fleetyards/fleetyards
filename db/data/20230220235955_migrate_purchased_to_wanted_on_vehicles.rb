# frozen_string_literal: true

class MigratePurchasedToWantedOnVehicles < ActiveRecord::Migration[7.0]
  def up
    bar = ProgressBar.new(Vehicle.count)

    Vehicle.find_each do |vehicle|
      DataMigrate::PurchasedToWantedJob.perform_async(vehicle.id)

      bar.increment!
    end
  end

  def down
  end
end
