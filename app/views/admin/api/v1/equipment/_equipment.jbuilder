# frozen_string_literal: true

extended = local_assigns.fetch(:extended, false)

json.cache! [
  "v6", equipment, equipment.retired?, equipment.facts, equipment.item_prices_cache_key, Manufacturer.artwork_version,
  extended
] do
  json.partial!("admin/api/v1/equipment/base", equipment:, extended:)
end
