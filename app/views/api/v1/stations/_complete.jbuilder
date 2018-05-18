# frozen_string_literal: true

json.cache! ['v1', station] do
  json.partial! 'api/v1/stations/base', station: station
  json.docks do
    json.array! station.docks, partial: 'api/v1/stations/dock', as: :dock
  end
  json.shops do
    json.array! station.shops, partial: 'api/v1/stations/shop', as: :shop
  end
  json.images do
    json.array! station.images, partial: 'api/v1/images/base', as: :image
  end
  json.partial! 'api/shared/dates', record: station
end
