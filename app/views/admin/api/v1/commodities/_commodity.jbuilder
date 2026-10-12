# frozen_string_literal: true

json.cache! ["v4", commodity, commodity.facts, commodity.item_prices_cache_key] do
  json.partial!("admin/api/v1/commodities/base", commodity:)
end
