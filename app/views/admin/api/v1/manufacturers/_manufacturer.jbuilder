# frozen_string_literal: true

json.cache! ["v1", manufacturer, manufacturer.shipyard_location&.link_cache_key] do
  json.partial!("admin/api/v1/manufacturers/base", manufacturer:)
end
