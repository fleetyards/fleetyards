# frozen_string_literal: true

json.cache! ["v1", "admin_inventory_item", item] do
  json.partial!("admin/api/v1/inventory_items/base", item:)
end
