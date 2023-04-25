class RemovePurchasedFromVehicles < ActiveRecord::Migration[7.0]
  def change
    remove_column :vehicles, :purchased, :boolean, default: false, null: false
  end
end
