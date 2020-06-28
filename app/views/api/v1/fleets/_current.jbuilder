# frozen_string_literal: true

# json.invitation fleet.invitation(current_user&.id)
# json.accepted_at fleet.accepted_at(current_user&.id)&.utc&.iso8601
# json.ships_filter fleet.ships_filter(current_user&.id)
# json.hangar_group_id fleet.hangar_group_id(current_user&.id)

json.my_role fleet.role(current_user&.id)
json.primary fleet.primary(current_user&.id)
json.cache! ['v1', fleet] do
  json.partial! 'api/v1/fleets/base', fleet: fleet
  json.partial! 'api/shared/dates', record: fleet
end
