# frozen_string_literal: true

json.cache! ["v1", "admin_fleet_inventory_item", item] do
  json.partial!("admin/api/v1/fleet_inventory_items/base", item:)
end
