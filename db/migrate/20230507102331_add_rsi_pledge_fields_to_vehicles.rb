class AddRsiPledgeFieldsToVehicles < ActiveRecord::Migration[7.0]
  def change
    add_column :vehicles, :rsi_pledge_id, :string
    add_column :vehicles, :rsi_pledge_synced_at, :datetime
  end
end
