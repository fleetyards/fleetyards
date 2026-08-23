# frozen_string_literal: true

json.cache! ["v1", component, component.item_prices_cache_key] do
  json.partial!("admin/api/v1/components/base", component:)
end
