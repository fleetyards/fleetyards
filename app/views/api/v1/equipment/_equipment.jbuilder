# frozen_string_literal: true

json.cache! ["v1", equipment, equipment.item_prices_cache_key] do
  json.partial!("api/v1/equipment/base", equipment:)
end
