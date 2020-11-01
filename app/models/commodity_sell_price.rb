# frozen_string_literal: true

class CommoditySellPrice < CommodityPrice
  after_destroy :update_shop_commodity
  after_save :update_shop_commodity

  def update_shop_commodity
    shop_commodity.update_sell_prices
  end
end
