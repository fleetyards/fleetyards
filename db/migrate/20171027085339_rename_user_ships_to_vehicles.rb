class RenameUserShipsToVehicles < ActiveRecord::Migration[5.1]
  def change
    rename_table :user_ships, :vehicles
  end
end
