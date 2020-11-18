class AddTankSizesToModels < ActiveRecord::Migration[6.0]
  def change
    add_column :models, :hydrogen_fuel_tank_size, :decimal, precision: 15, scale: 2
    add_column :models, :quantum_fuel_tank_size, :decimal, precision: 15, scale: 2
  end
end
