# frozen_string_literal: true

# `extended` is part of the key, not just an argument: the same component is
# rendered both ways -- slim in a catalogue page of 50, full on its own page --
# and without it in the key the first shape cached would be served as the other.
json.cache! [
  "v2", component, ::ScData::Source.current, component.item_prices_cache_key,
  Manufacturer.artwork_version, local_assigns.fetch(:extended, false)
] do
  json.partial!("api/v1/components/base", component:, extended: local_assigns.fetch(:extended, false))
end
