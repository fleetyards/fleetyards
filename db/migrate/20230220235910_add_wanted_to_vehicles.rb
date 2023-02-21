class AddWantedToVehicles < ActiveRecord::Migration[7.0]
  def change
    add_column :vehicles, :wanted, :boolean, default: false
  end
end
