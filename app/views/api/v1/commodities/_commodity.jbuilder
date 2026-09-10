# frozen_string_literal: true

json.cache! ["v1", commodity, ::ScData::Source.current, commodity.item_prices_cache_key] do
  json.partial!("api/v1/commodities/base", commodity:)
end
