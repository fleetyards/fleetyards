# frozen_string_literal: true

json.id station.id
json.name station.name
json.slug station.slug
json.location station.location
json.location_label station.location_label
json.type station.station_type
json.type_label station.station_type_label
json.classification station.classification
json.classification_label station.classification_label
json.habitable station.habitable
json.media do
  json.store_image do
    json.partial! "api/v1/shared/media_image", media_image: station.store_image
  end
  json.background_image station.random_image&.name&.url
end
json.description station.description
json.has_images station.images_count.positive?
json.shop_list_label station.shop_list_label
json.refinery station.refinery
json.cargo_hub station.cargo_hub
