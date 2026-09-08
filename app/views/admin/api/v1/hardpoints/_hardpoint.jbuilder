# frozen_string_literal: true

# The build row is in the key because the facts come from it: a build landing
# under an untouched slot leaves the row's own `updated_at` alone, so keying on
# the slot alone would serve the previous build's loadout. For a matrix slot
# `facts` is the slot itself and this collapses back to one entry.
json.cache! ["admin-v2", hardpoint, hardpoint.facts, hardpoint.facts.component, Manufacturer.artwork_version] do
  json.partial!("admin/api/v1/hardpoints/base", hardpoint:)
end
