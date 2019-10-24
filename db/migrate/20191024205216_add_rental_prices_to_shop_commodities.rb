class AddRentalPricesToShopCommodities < ActiveRecord::Migration[5.2]
  def change
    add_column :shop_commodities, :rent_price_1_day, :decimal, precision: 15, scale: 2
    add_column :shop_commodities, :rent_price_7_days, :decimal, precision: 15, scale: 2
    add_column :shop_commodities, :rent_price_30_days, :decimal, precision: 15, scale: 2
    remove_column :shop_commodities, :rent_price, :decimal, precision: 15, scale: 2
  end
end
