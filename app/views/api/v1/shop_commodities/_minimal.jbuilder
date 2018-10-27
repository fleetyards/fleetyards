# frozen_string_literal: true

json.cache! ['v1', shop_commodity] do
  json.partial! 'api/v1/shop_commodities/base', shop_commodity: shop_commodity
  json.commodity_item do
    json.partial! 'api/v1/shop_commodities/commodity_item', commodity_item: shop_commodity.commodity_item if shop_commodity.commodity_item.present?
  end
  json.commodity_item nil if shop_commodity.commodity_item.blank?
  json.partial! 'api/shared/dates', record: shop_commodity
end
