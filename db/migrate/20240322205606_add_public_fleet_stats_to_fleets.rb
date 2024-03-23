class AddPublicFleetStatsToFleets < ActiveRecord::Migration[7.1]
  def change
    add_column :fleets, :public_fleet_stats, :boolean, default: false
  end
end
