# frozen_string_literal: true

# The manager and the squadrons are part of the key because the fragment
# carries the manager's handle and profile urls and the squadrons' names,
# colours and icons, none of which touch the inventory when they change.
json.cache! ["v2", fleet_inventory, fleet_inventory.manager, *fleet_inventory.fleet_squadrons] do
  json.partial!("api/v1/fleet_inventories/base", fleet_inventory:)
end
