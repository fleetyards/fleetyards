# frozen_string_literal: true

json.cache! ["v1", commodity, commodity.item_prices_cache_key] do
  json.partial!("admin/api/v1/commodities/base", commodity:)
end
