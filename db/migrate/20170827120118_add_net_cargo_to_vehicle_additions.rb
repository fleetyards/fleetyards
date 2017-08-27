class AddNetCargoToVehicleAdditions < ActiveRecord::Migration[5.1]
  def change
    add_column :vehicle_additions, :net_cargo, :string
  end
end
