# frozen_string_literal: true

json.items do
  json.array! @vehicles, partial: "api/v1/public/vehicles/vehicle", as: :vehicle
end
json.partial! "api/shared/meta", result: @vehicles
