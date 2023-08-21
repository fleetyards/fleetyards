# frozen_string_literal: true

json.id shop.id
json.name shop.name
json.slug shop.slug
json.type shop.shop_type
json.type_label shop.shop_type_label
json.station_label shop.station_label
json.location shop.location
json.location_label shop.location_label
json.rental shop.rental
json.buying shop.buying
json.selling shop.selling

json.media({})
json.media do
  json.ignore_nil!
  json.store_image do
    json.partial! "api/v1/shared/media_image", media_image: shop.store_image
  end
end

json.refinery_terminal shop.refinery_terminal

json.station do
  json.partial! "api/v1/shops/station", station: shop.station
end

if local_assigns.fetch(:extended, false)
  json.celestial_object do
    json.partial! "api/v1/celestial_objects/base", celestial_object: shop.station.celestial_object
  end
end

json.partial! "api/shared/dates", record: shop

# DEPRECATED
json.store_image shop.store_image.url
json.store_image_large shop.store_image.large.url
json.store_image_medium shop.store_image.medium.url
json.store_image_small shop.store_image.small.url
