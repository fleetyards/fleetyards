# frozen_string_literal: true

json.cache! ["v1", "admin_inventory", inventory] do
  json.partial!("admin/api/v1/inventories/base", inventory:)
end
