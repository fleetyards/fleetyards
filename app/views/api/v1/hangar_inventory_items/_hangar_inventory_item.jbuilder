# frozen_string_literal: true

json.cache! ["v1", hangar_inventory_item] do
  json.partial!("api/v1/shared/inventory_item", inventory_item: hangar_inventory_item)
end
