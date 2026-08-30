# frozen_string_literal: true

json.cache! ["v1", "admin_fleet_inventory", inventory] do
  json.partial!("admin/api/v1/fleet_inventories/base", inventory:)
end
