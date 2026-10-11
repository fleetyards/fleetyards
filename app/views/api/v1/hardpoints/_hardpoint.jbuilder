# frozen_string_literal: true

# Keyed on the build row and its component, which `_base` renders, rather than
# the slot's own columns; and on every component price, since nested slots
# render their components' prices too. The locale, because components carry
# translated labels.
json.cache! [
  "v5", I18n.locale, hardpoint, ::ScData::Source.current, hardpoint.facts, hardpoint.facts.component,
  ItemPrice.cache_key_for("Component"), Manufacturer.artwork_version
] do
  json.partial!("api/v1/hardpoints/base", hardpoint:)
end
