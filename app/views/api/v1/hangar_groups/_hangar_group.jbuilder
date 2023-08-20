# frozen_string_literal: true

json.cache! ["v1", group] do
  json.partial!("api/v1/hangar_groups/base", group:)
end
json.vehiclesCount group.vehicles.count
