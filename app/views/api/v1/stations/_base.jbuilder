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

json.media({})
json.media do
  json.store_image do
    json.partial! "api/v1/shared/media_image", media_image: station.store_image
  end
  json.background_image station.random_image&.name&.url
end

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
  json.array! station.habitation_counts, partial: "api/v1/habitation_counts/base", as: :habitation_count
end

json.dock_counts do
  json.array! station.dock_counts, partial: "api/v1/dock_counts/base", as: :dock_count
end

json.celestial_object do
  json.partial! "api/v1/celestial_objects/base", celestial_object: station.celestial_object
end

if local_assigns.fetch(:extended, false)
  json.starsystem do
    json.partial! "api/v1/starsystems/base", starsystem: station.starsystem
  end
  json.shops do
    json.array! station.shops.visible.order(:name), partial: "api/v1/shops/base", as: :shop
  end
  json.docks do
    json.array! station.docks, partial: "api/v1/docks/base", as: :dock
  end
  json.habitations do
    json.array! station.habitations, partial: "api/v1/habitations/base", as: :habitation
  end
end

json.partial! "api/shared/dates", record: station
