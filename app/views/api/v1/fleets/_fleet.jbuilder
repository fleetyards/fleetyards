# frozen_string_literal: true

json.my_fleet fleet.my_fleet?(current_user&.id)
json.my_role fleet.role(current_user&.id) if fleet.role(current_user&.id)
json.primary fleet.primary(current_user&.id) if fleet.primary(current_user&.id)
json.cache! ["v1", fleet] do
  json.partial!("api/v1/fleets/base", fleet:)
end
