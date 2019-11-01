# frozen_string_literal: true

json.cache! ['v1', result] do
  json.id result.id
  json.result_type result.class.name.underscore
  case result.class.name
  when 'Model'
    json.partial! 'api/v1/models/base', model: result
  when 'ShopCommodity'
    json.partial! 'api/v1/shop_commodities/base', shop_commodity: result
  when 'Shop'
    json.partial! 'api/v1/shops/base', shop: result
  when 'Station'
    json.partial! 'api/v1/stations/base', station: result
  when 'CelestialObject'
    json.partial! 'api/v1/celestial_objects/base', celestial_object: result
  when 'Starsystem'
    json.partial! 'api/v1/starsystems/base', starsystem: result
  end
  json.partial! 'api/shared/dates', record: result
end
