# frozen_string_literal: true

json.array! @fleets do |fleet|
  json.partial! "api/v1/fleets/fleet", fleet:, my_fleet: true
end
