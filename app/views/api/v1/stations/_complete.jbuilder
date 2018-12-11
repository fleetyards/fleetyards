# frozen_string_literal: true

json.cache! ['v1', station] do
  json.partial! 'api/v1/stations/base', station: station
  json.images do
    json.array! station.images, partial: 'api/v1/images/base', as: :image
  end
  json.partial! 'api/shared/dates', record: station
end
