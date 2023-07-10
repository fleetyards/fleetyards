# frozen_string_literal: true

json.cache! ["v1", station] do
  json.partial!("api/v1/stations/base", station:)
  json.celestial_object do
    json.partial! "api/v1/celestial_objects/base", celestial_object: station.celestial_object
  end
  json.partial! "api/shared/dates", record: station
end
