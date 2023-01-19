# frozen_string_literal: true

json.cache! ["v1", station] do
  json.partial!("api/v1/stations/base", station:)
  json.partial! "api/shared/dates", record: station
end
