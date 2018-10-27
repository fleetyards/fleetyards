# frozen_string_literal: true

json.cache! ['v1', shop] do
  json.partial! 'api/v1/shops/base', shop: shop
  json.station do
    json.partial! 'api/v1/stations/base', station: shop.station
  end
  json.celestial_object do
    json.partial! 'api/v1/celestial_objects/base', celestial_object: shop.station.celestial_object
  end
  json.partial! 'api/shared/dates', record: shop
end
