# frozen_string_literal: true

json.name station.name
json.slug station.slug
json.location station.location
json.location_label station.location_label
json.type station.station_type
json.type_label station.station_type_label
json.classification station.classification
json.classification_label station.classification_label
json.habitable station.habitable
json.store_image station.store_image.url
json.store_image_large station.store_image.large.url
json.store_image_medium station.store_image.medium.url
json.store_image_small station.store_image.small.url
json.description station.description
json.background_image station.random_image&.name&.url
json.has_images station.images_count.positive?
json.shop_list_label station.shop_list_label
json.refinery station.refinery
json.cargo_hub station.cargo_hub
json.habitation_counts do
  json.array! station.habitation_counts, partial: 'api/v1/stations/habitation_count', as: :habitation_count
end
json.dock_counts do
  json.array! station.dock_counts, partial: 'api/v1/stations/dock_count', as: :dock_count
end
json.celestial_object do
  json.partial! 'api/v1/celestial_objects/base', celestial_object: station.celestial_object
end
