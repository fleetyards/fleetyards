# frozen_string_literal: true

json.items do
  json.array! @fleets, partial: "admin/api/v1/fleets/fleet", as: :fleet
end
json.partial! "api/shared/meta", result: @fleets
