class AddAverageFieldsToTradeRoutes < ActiveRecord::Migration[6.0]
  def change
    add_column :trade_routes, :average_profit_per_unit, :decimal, precision: 15, scale: 2
    add_column :trade_routes, :average_profit_per_unit_percent, :decimal, precision: 15, scale: 2
  end
end
