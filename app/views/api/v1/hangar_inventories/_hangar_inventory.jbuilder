# frozen_string_literal: true

json.cache! ["v1", hangar_inventory] do
  json.partial!("api/v1/shared/inventory", inventory: hangar_inventory)
end
