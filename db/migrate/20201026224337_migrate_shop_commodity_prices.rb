class MigrateShopCommodityPrices < ActiveRecord::Migration[6.0]
  def up
    ShopCommodity.find_each do |shop_item|
      if shop_item.buy_price.present?
        CommodityBuyPrice.create(price: shop_item.buy_price, shop_commodity_id: shop_item.id)
      end
      if shop_item.sell_price.present?
        CommoditySellPrice.create(price: shop_item.sell_price, shop_commodity_id: shop_item.id)
      end
      if shop_item.rental_price_1_day.present?
        CommodityRentalPrice.create(price: shop_item.rental_price_1_day, time_range: '1-day', shop_commodity_id: shop_item.id)
      end
      if shop_item.rental_price_3_days.present?
        CommodityRentalPrice.create(price: shop_item.rental_price_3_days, time_range: '3-days', shop_commodity_id: shop_item.id)
      end
      if shop_item.rental_price_7_days.present?
        CommodityRentalPrice.create(price: shop_item.rental_price_7_days, time_range: '7-days', shop_commodity_id: shop_item.id)
      end
      if shop_item.rental_price_30_days.present?
        CommodityRentalPrice.create(price: shop_item.rental_price_30_days, time_range: '30-days', shop_commodity_id: shop_item.id)
      end
    end
  end
end
