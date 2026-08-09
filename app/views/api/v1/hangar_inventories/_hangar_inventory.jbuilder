# frozen_string_literal: true

json.cache! ["v1", hangar_inventory] do
  json.partial!("api/v1/hangar_inventories/base", hangar_inventory:)
end
