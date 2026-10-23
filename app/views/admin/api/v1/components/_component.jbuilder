# frozen_string_literal: true

extended = local_assigns.fetch(:extended, false)

json.cache! ["v5", I18n.locale, component, component.item_prices_cache_key, Manufacturer.artwork_version, extended] do
  json.partial!("admin/api/v1/components/base", component:, extended:)
end
