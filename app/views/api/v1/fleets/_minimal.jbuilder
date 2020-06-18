# frozen_string_literal: true

json.my_role fleet.role(current_user&.id)
json.my_fleet fleet.my_fleet?(current_user&.id)
json.primary fleet.primary(current_user&.id)
json.cache! ['v1', fleet] do
  json.partial! 'api/v1/fleets/base', fleet: fleet
  json.partial! 'api/shared/dates', record: fleet
end
