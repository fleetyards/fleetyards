# frozen_string_literal: true

json.cache! ["v2", vehicle.model, vehicle] do
  json.partial!("api/v2/hangar/public/vehicles/base", vehicle:)
  json.partial! "api/shared/dates", record: vehicle
end
