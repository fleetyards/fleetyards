# frozen_string_literal: true

json.cache! ["v1", fleet_inventory_item] do
  json.partial!("api/v1/fleet_inventory_items/base", fleet_inventory_item:)
end
