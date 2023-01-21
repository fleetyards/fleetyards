# frozen_string_literal: true

json.partial! "api/shared/pagination_metadata", scope: @vehicles, model: Vehicle
json.items do
  json.array! @vehicles, partial: "api/v2/hangar/public/vehicles/minimal", as: :vehicle
end
