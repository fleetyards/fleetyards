class Add3DaysRentalToShopCommodities < ActiveRecord::Migration[5.2]
  def change
    add_column :shop_commodities, :rent_price_3_days, :decimal, precision: 15, scale: 2
  end
end
