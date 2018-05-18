# frozen_string_literal: true

json.name station.name
json.slug station.slug
json.type Station.human_enum_name(:station_type, station.station_type)
json.planet do
  json.partial! 'api/v1/stations/planet', planet: station.planet if station.planet.present?
end
json.planet nil if station.planet.blank?
json.starsystem do
  json.partial! 'api/v1/stations/starsystem', starsystem: station.starsystem if station.planet.present? && station.starsystem.present?
end
json.starsystem nil if station.planet.blank? || (station.planet.present? && station.starsystem.blank?)
