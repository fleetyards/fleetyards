# frozen_string_literal: true

json.name celestial_object.name
json.slug celestial_object.slug

json.danger celestial_object.sensor_danger
json.description celestial_object.description
json.designation celestial_object.designation
json.economy celestial_object.sensor_economy
json.fairchanceact celestial_object.fairchanceact
json.habitable celestial_object.habitable
json.location_label celestial_object.location_label

json.media({})
json.media do
  json.store_image do
    json.partial! "api/v1/shared/media_image", media_image: celestial_object.store_image
  end
end

json.population celestial_object.sensor_population
json.size celestial_object.size
json.sub_type celestial_object.sub_type
json.type celestial_object.object_type&.humanize

json.starsystem do
  json.partial! "api/v1/starsystems/base", starsystem: celestial_object.starsystem
end

if local_assigns.fetch(:extended, false)
  json.parent do
    json.partial! "api/v1/celestial_objects/base", celestial_object: celestial_object.parent if celestial_object.parent.present?
  end
  json.moons do
    moons = celestial_object.moons.visible.order(designation: :asc).visible.order(:name)
    json.array! moons, partial: "api/v1/celestial_objects/base", as: :celestial_object if moons.present?
  end
end

json.partial! "api/shared/dates", record: celestial_object

# DEPRECATED

json.store_image celestial_object.store_image.url
json.store_image_large celestial_object.store_image.large.url
json.store_image_medium celestial_object.store_image.medium.url
json.store_image_small celestial_object.store_image.small.url
