class AddExternalFuelTanksToModels < ActiveRecord::Migration[7.2]
  def change
    add_column :models, :external_fuel_tanks, :string
  end
end
