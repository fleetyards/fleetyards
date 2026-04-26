# frozen_string_literal: true

json.cache! ["v1", fleet_inventory] do
  json.partial!("api/v1/fleet_inventories/base", fleet_inventory:)
end
