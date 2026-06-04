# frozen_string_literal: true

json.items @fleets do |fleet|
  json.partial! "admin/api/v1/fleets/option", fleet: fleet
end
json.partial! "api/shared/meta", result: @fleets
