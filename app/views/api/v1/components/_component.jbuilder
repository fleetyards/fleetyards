# frozen_string_literal: true

# The version leads the key so a payload change invalidates every fragment: v2
# was `description` and `requiredTags`, v3 is `tags`, v4 is a flight blade's
# `catalogued`, v5 is `durability`, v6 is `temperature` and `misfire`, v7 is each price's `shop`, v8 lists `boughtAt` best paid first. A cached fragment is a rendered payload, so a new field is
# invisible on every component that has been served once until this moves. The locale is in it because `itemClassLabel` is
# translated, and a fragment filled in one language was served to every reader.
# Every component price is in it because the component's own ports render the
# prices of the components they hold. This one's own key stays alongside: it
# loads `item_prices`, which `_base` then reads for both directions at once.
json.cache! [
  "v8", I18n.locale, component, ::ScData::Source.current, component.item_prices_cache_key,
  ItemPrice.cache_key_for("Component"), Manufacturer.artwork_version
] do
  json.partial!("api/v1/components/base", component:)
end
