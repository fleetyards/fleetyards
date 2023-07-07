# frozen_string_literal: true

json.name celestial_object.name
json.slug celestial_object.slug
json.type celestial_object.object_type&.humanize
json.designation celestial_object.designation
json.media do
  json.store_image do
    json.partial! "api/v1/shared/media_image", media_image: celestial_object.store_image
  end
end
json.store_image celestial_object.store_image.url
json.store_image_large celestial_object.store_image.large.url
json.store_image_medium celestial_object.store_image.medium.url
json.store_image_small celestial_object.store_image.small.url
json.description celestial_object.description
json.habitable celestial_object.habitable
json.fairchanceact celestial_object.fairchanceact
json.sub_type celestial_object.sub_type
json.size celestial_object.size
json.danger celestial_object.sensor_danger
json.economy celestial_object.sensor_economy
json.population celestial_object.sensor_population
json.location_label celestial_object.location_label
json.starsystem do
  json.partial! "api/v1/starsystems/base", starsystem: celestial_object.starsystem
end
