# frozen_string_literal: true

json.cache! ["v2", vehicle.model, ::ScData::Source.current, Manufacturer.artwork_version, vehicle] do
  json.partial!("api/v1/vehicles/base", vehicle:)
end
