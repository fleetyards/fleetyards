# frozen_string_literal: true

json.items do
  json.array! @vehicles, partial: "admin/api/v1/vehicles/vehicle", as: :vehicle
end
json.partial! "api/shared/meta", result: @vehicles
