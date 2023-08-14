# frozen_string_literal: true

json.my_fleet fleet.my_fleet?(current_user&.id)
json.cache! ["v1", fleet] do
  json.partial!("api/v1/fleets/base", fleet:)
  json.partial! "api/shared/dates", record: fleet
end
