class AddBundledToVehicles < ActiveRecord::Migration[7.2]
  def change
    add_column :vehicles, :bundled, :boolean, default: false, null: false
    add_index :vehicles, [:vehicle_id, :bundled]
  end
end
