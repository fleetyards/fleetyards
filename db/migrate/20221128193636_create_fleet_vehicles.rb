class CreateFleetVehicles < ActiveRecord::Migration[6.1]
  def change
    create_table :fleet_vehicles, id: :uuid do |t|
      t.uuid :vehicle_id
      t.uuid :fleet_id

      t.timestamps
    end
  end
end
