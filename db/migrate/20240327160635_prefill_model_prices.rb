class PrefillModelPrices < ActiveRecord::Migration[7.1]
  def up
    CommodityPrice.includes(:shop_commodity).where(
      shop_commodity: {commodity_item_type: "Model"},
      confirmed: true
    ).find_each do |commodity_price|
      ModelPrice.create!(
        model_id: commodity_price.shop_commodity.commodity_item_id,
        price_type: price_type(commodity_price),
        time_range: commodity_price.time_range,
        price: commodity_price.price,
        location: [
          commodity_price.shop_commodity.shop.name,
          commodity_price.shop_commodity.shop.location_label
        ].join(" ")
      )
    end
  end

  def down
    ModelPrice.destroy_all
  end

  protected def price_type(commodity_price)
    case commodity_price.type
    when "CommodityBuyPrice" then "buy"
    when "CommoditySellPrice" then "sell"
    when "CommodityRentalPrice" then "rental"
    else raise "Unknown price type: #{commodity_price.type}"
    end
  end
end
