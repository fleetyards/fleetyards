# frozen_string_literal: true

# The version leads the key so a payload change invalidates every fragment: v2
# is the `*Label` fields, v4 lists `boughtAt` best paid first, v5 falls `storeImage` back to the angled view, v6 lists carry `media.angledView`. The locale is in it because those labels are
# translated, and a fragment filled by one reader's language would otherwise be
# served to everyone. The builds are in it because a load writes them without
# touching the row: without them a fragment filled before the load keeps its
# facts and `retired`.
# `extended` is the detail payload, which adds the views a list leaves out.
extended = local_assigns.fetch(:extended, false)

json.cache! [
  "v6", I18n.locale, equipment, ::ScData::Source.current, equipment.retired?, equipment.facts,
  equipment.item_prices_cache_key, Manufacturer.artwork_version, extended
] do
  json.partial!("api/v1/equipment/base", equipment:, extended:)
end
