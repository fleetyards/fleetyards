# frozen_string_literal: true

json.cache! ["v2", vehicle.model, ::ScData::Source.current, Manufacturer.artwork_version, vehicle.user, vehicle] do
  json.partial!("api/v1/public/vehicles/base", vehicle:)
end
