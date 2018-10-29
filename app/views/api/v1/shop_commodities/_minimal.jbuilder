# frozen_string_literal: true

json.cache! ['v1', shop_commodity] do
  json.partial! 'api/v1/shop_commodities/base', shop_commodity: shop_commodity
  json.manufacturer do
    json.partial! 'api/v1/shop_commodities/manufacturer', manufacturer: shop_commodity.manufacturer if shop_commodity.manufacturer.present?
  end
  json.manufacturer nil if shop_commodity.manufacturer.blank?
  json.partial! 'api/shared/dates', record: shop_commodity
end
