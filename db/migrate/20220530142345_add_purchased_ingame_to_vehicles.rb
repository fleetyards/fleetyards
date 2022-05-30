class AddPurchasedIngameToVehicles < ActiveRecord::Migration[6.1]
  def change
    add_column :vehicles, :purchased_ingame, :boolean, default: false
  end
end
