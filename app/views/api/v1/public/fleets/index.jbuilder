# frozen_string_literal: true

json.items do
  json.array! @fleets, partial: "api/v1/public/fleets/directory_entry", as: :fleet
end
json.partial! "api/shared/meta", result: @fleets
