# frozen_string_literal: true

# The version leads the key so a payload change invalidates every fragment: v2
# is the `*Label` fields. The locale is in it because those labels are
# translated, and a fragment filled by one reader's language would otherwise be
# served to everyone.
json.cache! [
  "v2", I18n.locale, equipment, ::ScData::Source.current, equipment.item_prices_cache_key,
  Manufacturer.artwork_version
] do
  json.partial!("api/v1/equipment/base", equipment:)
end
