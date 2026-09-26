# frozen_string_literal: true

# The version leads the key so a payload change invalidates every fragment: v2
# was `description` and `requiredTags`, v3 is `tags`, v4 is a flight blade's
# `catalogued`. A cached fragment is a rendered payload, so a new field is
# invisible on every component that has been served once until this moves. The locale is in it because `itemClassLabel` is
# translated, and a fragment filled in one language was served to every reader.
json.cache! [
  "v4", I18n.locale, component, ::ScData::Source.current, component.item_prices_cache_key,
  Manufacturer.artwork_version
] do
  json.partial!("api/v1/components/base", component:)
end
