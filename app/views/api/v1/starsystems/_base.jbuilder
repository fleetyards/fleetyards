# frozen_string_literal: true

json.name starsystem.name
json.slug starsystem.slug
json.media do
  json.store_image do
    json.partial! "api/v1/shared/media_image", media_image: starsystem.store_image
  end
end
json.map_x starsystem.map_x
json.map_y starsystem.map_y
json.description starsystem.description
json.type starsystem.system_type&.humanize
json.size starsystem.aggregated_size
json.population starsystem.aggregated_population
json.economy starsystem.aggregated_economy
json.danger starsystem.aggregated_danger
json.status starsystem.status
json.location_label starsystem.location_label

if local_assigns.fetch(:extended, false)
  celestial_objects = starsystem.celestial_objects.visible.order(designation: :asc).visible.main.order(:designation)
  json.celestialObjects do
    json.array! celestial_objects, partial: "api/v1/celestial_objects/base", as: :celestial_object
  end
end

json.partial! "api/shared/dates", record: starsystem

# DEPRECATED
json.store_image starsystem.store_image.url
json.store_image_large starsystem.store_image.large.url
json.store_image_medium starsystem.store_image.medium.url
json.store_image_small starsystem.store_image.small.url
