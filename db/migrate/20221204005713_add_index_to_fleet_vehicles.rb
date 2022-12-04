class AddIndexToFleetVehicles < ActiveRecord::Migration[6.1]
  def change
    add_index :fleet_vehicles, [:fleet_id, :vehicle_id], unique: true
  end
end
