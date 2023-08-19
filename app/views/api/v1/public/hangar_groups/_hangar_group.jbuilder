# frozen_string_literal: true

json.cache! ["v1", group] do
  json.partial!("api/v1/public/hangar_groups/base", group:)
end
json.vehiclesCount group.vehicles.count
