# frozen_string_literal: true

# The manager is part of the key because the fragment now carries their handle
# and profile urls, which change without touching the inventory.
json.cache! ["v1", fleet_inventory, fleet_inventory.manager] do
  json.partial!("api/v1/fleet_inventories/base", fleet_inventory:)
end
