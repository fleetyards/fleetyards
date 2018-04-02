class RemoveNullConstraintFromTradeCommodities < ActiveRecord::Migration[5.1]
  def change
    reversible do
      change_column :trade_commodities, :buy_price, :decimal, precision: 15, scale: 2, default: 0.0, null: true
      change_column :trade_commodities, :sell_price, :decimal, precision: 15, scale: 2, default: 0.0, null: true
    end
  end
end
