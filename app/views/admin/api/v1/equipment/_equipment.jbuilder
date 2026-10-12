# frozen_string_literal: true

json.cache! ["v4", equipment, equipment.facts, equipment.item_prices_cache_key, Manufacturer.artwork_version] do
  json.partial!("admin/api/v1/equipment/base", equipment:)
end
