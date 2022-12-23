# frozen_string_literal: true

json.cache! ['v2', vehicle.model, vehicle] do
  json.partial! 'api/v2/hangar/vehicles/base', vehicle: vehicle
  json.partial! 'api/shared/dates', record: vehicle
  # json.partial! 'api/shared/record_links', record: vehicle
end
