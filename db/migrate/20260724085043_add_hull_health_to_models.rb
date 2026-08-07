class AddHullHealthToModels < ActiveRecord::Migration[8.1]
  def change
    add_column :models, :hull_health, :decimal, precision: 15, scale: 2
  end
end
