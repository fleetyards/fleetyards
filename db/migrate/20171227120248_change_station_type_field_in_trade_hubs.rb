class ChangeStationTypeFieldInTradeHubs < ActiveRecord::Migration[5.1]
  def change
    remove_column :trade_hubs, :station_type, :string
    add_column :trade_hubs, :station_type, :integer
  end
end
