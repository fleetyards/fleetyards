# frozen_string_literal: true

# The version leads the key so a payload change invalidates every fragment: v2
# was `description` and `requiredTags`, v3 is `tags`. A cached fragment is a
# rendered payload, so a new field is invisible on every component that has been
# served once until this moves.
json.cache! [
  "v3", component, ::ScData::Source.current, component.item_prices_cache_key,
  Manufacturer.artwork_version
] do
  json.partial!("api/v1/components/base", component:)
end
