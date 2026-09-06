# frozen_string_literal: true

json.cache! ["v1", component, component.item_prices_cache_key, Manufacturer.artwork_version] do
  json.partial!("api/v1/components/base", component:)
end
