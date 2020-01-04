# frozen_string_literal: true

json.cache! ['v1', station] do
  json.partial! 'api/v1/stations/base', station: station
  json.starsystem do
    json.partial! 'api/v1/starsystems/base', starsystem: station.starsystem
  end
  json.shops do
    json.array! station.shops.visible.order(:name), partial: 'api/v1/shops/base', as: :shop
  end
  json.docks do
    json.array! station.docks, partial: 'api/v1/stations/dock', as: :dock
  end
  json.habitations do
    json.array! station.habitations, partial: 'api/v1/stations/habitation', as: :habitation
  end
  json.images do
    json.array! station.images, partial: 'api/v1/images/base', as: :image
  end
  json.partial! 'api/shared/dates', record: station
end
