# frozen_string_literal: true

json.cache! ['v1', commodity_price] do
  json.partial! 'admin/api/v1/commodity_prices/base', commodity_price: commodity_price
  json.shop_commodity do
    json.null! if commodity_price.shop_commodity.blank?
    json.partial! 'admin/api/v1/shop_commodities/base', shop_commodity: commodity_price.shop_commodity if commodity_price.shop_commodity.present?
  end
  json.partial! 'api/shared/dates', record: commodity_price
end
