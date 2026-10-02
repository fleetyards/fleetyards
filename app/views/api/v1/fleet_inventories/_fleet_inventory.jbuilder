# frozen_string_literal: true

# The manager, the squadrons and the linked place are part of the key because
# the fragment carries the manager's handle and profile urls, the squadrons'
# names, colours and icons and the place's name, none of which touch the
# inventory when they change.
json.cache! ["v4", fleet_inventory, fleet_inventory.manager, *fleet_inventory.fleet_squadrons, fleet_inventory.linked_location&.link_cache_key].compact do
  json.partial!("api/v1/fleet_inventories/base", fleet_inventory:)
end
