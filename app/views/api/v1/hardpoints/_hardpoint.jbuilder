# frozen_string_literal: true

# Keyed on the build row and its component, which `_base` renders, rather than
# the slot's own columns.
json.cache! ["v4", hardpoint, ::ScData::Source.current, hardpoint.facts, hardpoint.facts.component, Manufacturer.artwork_version] do
  json.partial!("api/v1/hardpoints/base", hardpoint:)
end
