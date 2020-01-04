# frozen_string_literal: true

json.cache! ['v1', vehicle.model, vehicle] do
  json.partial! 'api/v1/vehicles/base_public', vehicle: vehicle
  json.partial! 'api/shared/dates', record: vehicle
end
