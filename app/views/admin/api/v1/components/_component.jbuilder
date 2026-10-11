# frozen_string_literal: true

json.cache! ["v5", I18n.locale, component, component.item_prices_cache_key, Manufacturer.artwork_version] do
  json.partial!("admin/api/v1/components/base", component:)
end
