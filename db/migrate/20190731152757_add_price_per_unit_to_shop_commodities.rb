class AddPricePerUnitToShopCommodities < ActiveRecord::Migration[5.2]
  def change
    add_column :shop_commodities, :price_per_unit, :boolean, default: false
  end
end
