# frozen_string_literal: true

json.items @fleets do |fleet|
  json.partial! "admin/api/v1/fleets/fleet", fleet: fleet
  # Outside the cached fleet: the roster changes without touching the fleet.
  json.memberCount fleet.member_count
end
json.partial! "api/shared/meta", result: @fleets
