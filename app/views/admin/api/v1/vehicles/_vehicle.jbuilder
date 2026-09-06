# frozen_string_literal: true

json.cache! ["v1", vehicle.model, Manufacturer.artwork_version, vehicle] do
  json.partial!("admin/api/v1/vehicles/base", vehicle:)
end
