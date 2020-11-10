class AddAverageFieldsToShopCommodity < ActiveRecord::Migration[6.0]
  def change
    add_column :shop_commodities, :average_buy_price, :decimal, precision: 15, scale: 2
    add_column :shop_commodities, :average_sell_price, :decimal, precision: 15, scale: 2
    add_column :shop_commodities, :average_rental_price_1_day, :decimal, precision: 15, scale: 2
    add_column :shop_commodities, :average_rental_price_3_days, :decimal, precision: 15, scale: 2
    add_column :shop_commodities, :average_rental_price_7_days, :decimal, precision: 15, scale: 2
    add_column :shop_commodities, :average_rental_price_30_days, :decimal, precision: 15, scale: 2
    rename_column :shop_commodities, :rent_price_1_day, :rental_price_1_day
    rename_column :shop_commodities, :rent_price_3_days, :rental_price_3_days
    rename_column :shop_commodities, :rent_price_7_days, :rental_price_7_days
    rename_column :shop_commodities, :rent_price_30_days, :rental_price_30_days
  end
end
