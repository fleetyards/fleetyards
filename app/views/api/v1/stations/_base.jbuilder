# frozen_string_literal: true

json.name station.name
json.slug station.slug
json.type station.station_type_label
json.store_image station.store_image.url
json.planet do
  json.partial! 'api/v1/stations/planet', planet: station.planet if station.planet.present?
end
json.planet nil if station.planet.blank?
json.starsystem do
  json.partial! 'api/v1/stations/starsystem', starsystem: station.starsystem if station.starsystem.present?
end
json.starsystem nil if station.starsystem.blank?
json.ship_counts do
  json.array! station.ship_counts, partial: 'api/v1/stations/ship_count', as: :ship_count
end
