class AddRsiPledgeIdToVehicleModules < ActiveRecord::Migration[7.0]
  def change
    add_column :vehicle_modules, :rsi_pledge_id, :string
    add_column :vehicle_modules, :rsi_pledge_synced_at, :datetime
  end
end
