# frozen_string_literal: true

json.cache! ['v1', shop_commodity, shop_commodity.commodity_item] do
  json.partial! 'api/v1/shop_commodities/base', shop_commodity: shop_commodity
  json.partial! 'api/shared/dates', record: shop_commodity
end
