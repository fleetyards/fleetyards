class AddPublicToVehicles < ActiveRecord::Migration[5.2]
  def change
    add_column :vehicles, :public, :boolean, default: true
    add_column :users, :public_hangar, :boolean, default: true
  end
end
