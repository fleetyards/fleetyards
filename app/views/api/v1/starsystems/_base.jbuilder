# frozen_string_literal: true

json.name starsystem.name
json.slug starsystem.slug
json.store_image starsystem.store_image.url
json.store_image_medium starsystem.store_image.medium.url
json.store_image_small starsystem.store_image.small.url
json.map_x starsystem.map_x
json.map_y starsystem.map_y
json.description starsystem.description
json.type starsystem.system_type&.humanize
json.size starsystem.aggregated_size
json.population starsystem.aggregated_population
json.economy starsystem.aggregated_economy
json.danger starsystem.aggregated_danger
json.status starsystem.status
