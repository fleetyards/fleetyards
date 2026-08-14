# frozen_string_literal: true

json.cache! ["v1", inventory_item] do
  json.partial!("api/v1/shared/inventory_item", inventory_item:)
end
