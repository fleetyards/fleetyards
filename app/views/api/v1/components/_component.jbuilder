# frozen_string_literal: true

# `v2` rather than `v1`: the payload gained `description` and `requiredTags`,
# and a fragment cached under the old key would go on serving the shape without
# them.
json.cache! [
  "v2", component, ::ScData::Source.current, component.item_prices_cache_key,
  Manufacturer.artwork_version
] do
  json.partial!("api/v1/components/base", component:)
end
