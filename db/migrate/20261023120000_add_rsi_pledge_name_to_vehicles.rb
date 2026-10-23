class AddRsiPledgeNameToVehicles < ActiveRecord::Migration[8.1]
  def change
    add_column :vehicles, :rsi_pledge_name, :string
  end
end
