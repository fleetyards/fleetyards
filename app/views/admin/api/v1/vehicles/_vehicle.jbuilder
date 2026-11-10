# frozen_string_literal: true

json.cache! ["v9", vehicle.model, vehicle.model&.facts, Manufacturer.artwork_version, vehicle, vehicle.module_package] do
  json.partial!("admin/api/v1/vehicles/base", vehicle:)
end
