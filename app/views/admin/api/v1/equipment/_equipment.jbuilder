# frozen_string_literal: true

json.cache! ["v2", equipment, equipment.item_prices_cache_key, Manufacturer.artwork_version] do
  json.partial!("admin/api/v1/equipment/base", equipment:)
end
