# frozen_string_literal: true

json.cache! ["v1", equipment, ::ScData::Source.current, equipment.item_prices_cache_key, Manufacturer.artwork_version] do
  json.partial!("api/v1/equipment/base", equipment:)
end
