# frozen_string_literal: true

json.items do
  json.array! @stations, partial: "admin/api/v1/stations/minimal", as: :station
end
json.partial! "api/shared/meta", result: @stations
