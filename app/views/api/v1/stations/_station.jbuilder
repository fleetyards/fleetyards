# frozen_string_literal: true

json.cache! ["v1", station] do
  json.partial!("api/v1/stations/base", station:)
  json.celestial_object do
    json.partial! "api/v1/celestial_objects/minimal", celestial_object: station.celestial_object
  end
  json.starsystem do
    json.partial! "api/v1/starsystems/minimal", starsystem: station.starsystem
  end
  json.shops do
    json.array! station.shops.visible.order(:name), partial: "api/v1/shops/minimal", as: :shop
  end
  json.docks do
    json.array! station.docks, partial: "api/v1/docks/base", as: :dock
  end
  json.habitations do
    json.array! station.habitations, partial: "api/v1/habitations/base", as: :habitation
  end
  json.images do
    json.array! station.images, partial: "api/v1/images/minimal", as: :image
  end
  json.partial! "api/shared/dates", record: station
end
