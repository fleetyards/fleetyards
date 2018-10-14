# frozen_string_literal: true

json.cache! ['v1', shop] do
  json.partial! 'api/v1/shops/base', shop: shop
  json.station do
    json.partial! 'api/v1/stations/base', station: shop.station
  end
  json.partial! 'api/shared/dates', record: shop
end
