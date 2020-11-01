# frozen_string_literal: true

class CommodityRentalPrice < CommodityPrice
  enum time_range: { '1-day': 0, '3-days': 1, '7-days': 2, '30-days': 3 }

  after_destroy :update_shop_commodity
  after_save :update_shop_commodity

  def update_shop_commodity
    shop_commodity.update_1_day_prices if time_range == '1-day'
    shop_commodity.update_3_days_prices if time_range == '3-days'
    shop_commodity.update_7_days_prices if time_range == '7-days'
    shop_commodity.update_30_days_prices if time_range == '30-days'
  end
end
