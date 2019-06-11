# frozen_string_literal: true

json.name celestial_object.name
json.slug celestial_object.slug
json.type celestial_object.object_type&.humanize
json.designation celestial_object.designation
json.store_image celestial_object.store_image.url
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
