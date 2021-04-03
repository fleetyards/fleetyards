class AddPublicFlagToFleets < ActiveRecord::Migration[6.1]
  def change
    add_column :fleets, :public_fleet, :boolean, default: false
  end
end
