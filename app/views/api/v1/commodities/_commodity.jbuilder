# frozen_string_literal: true

# The builds are in the key because a load writes them without touching the row:
# without them a fragment filled before the load keeps its facts and `retired`.
json.cache! [
  "v6", commodity, ::ScData::Source.current, commodity.retired?, commodity.facts, commodity.item_prices_cache_key
] do
  json.partial!("api/v1/commodities/base", commodity:)
end
