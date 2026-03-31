class AddFuelConsumptionToModels < ActiveRecord::Migration[7.1]
  def change
    add_column :models, :fuel_consumption, :decimal, precision: 15, scale: 2
  end
end
