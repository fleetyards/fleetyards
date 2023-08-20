# frozen_string_literal: true

json.cache! ["v1", vehicle.model, vehicle.user, vehicle] do
  json.partial!("api/v1/public/vehicles/base", vehicle:)
end
