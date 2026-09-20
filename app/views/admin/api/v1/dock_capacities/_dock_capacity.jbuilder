# frozen_string_literal: true

json.cache! ["v1", dock_capacity] do
  json.partial!("admin/api/v1/dock_capacities/base", dock_capacity:)
end
