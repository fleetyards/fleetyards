# frozen_string_literal: true

json.name station.name
json.slug station.slug
json.location station.location
json.type station.station_type
json.type_label station.station_type_label
json.store_image station.store_image.url
json.store_image_medium station.store_image.medium.url
json.store_image_small station.store_image.small.url
json.description station.description
json.celestial_object do
  json.partial! 'api/v1/celestial_objects/base', celestial_object: station.celestial_object
end
json.starsystem do
  json.partial! 'api/v1/starsystems/base', starsystem: station.starsystem
end
json.shops do
  json.array! station.shops.visible.order(:name), partial: 'api/v1/shops/base', as: :shop
end
json.dock_counts do
  json.array! station.dock_counts, partial: 'api/v1/stations/dock_count', as: :dock_count
end
json.docks do
  json.array! station.docks, partial: 'api/v1/stations/dock', as: :dock
end
json.habitation_counts do
  json.array! station.habitation_counts, partial: 'api/v1/stations/habitation_count', as: :habitation_count
end
json.habitations do
  json.array! station.habitations, partial: 'api/v1/stations/habitation', as: :habitation
end
