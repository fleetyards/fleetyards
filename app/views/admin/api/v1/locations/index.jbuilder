# frozen_string_literal: true

json.items do
  json.array! @locations, partial: "admin/api/v1/locations/location", as: :location
end
json.partial! "api/shared/meta", result: @locations
