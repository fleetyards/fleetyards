class AddFieldsToModels < ActiveRecord::Migration[6.0]
  def change
    add_column :models, :cargo_holds, :string
    add_column :models, :hydrogen_fuel_tanks, :string
    add_column :models, :quantum_fuel_tanks, :string
  end
end
