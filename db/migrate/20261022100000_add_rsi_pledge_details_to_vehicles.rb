class AddRsiPledgeDetailsToVehicles < ActiveRecord::Migration[8.1]
  def change
    add_column :vehicles, :rsi_pledge_melt_value, :decimal, precision: 15, scale: 2
    add_column :vehicles, :rsi_pledge_meltable, :boolean
    add_column :vehicles, :rsi_pledge_item_count, :integer
  end
end
