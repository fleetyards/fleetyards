# frozen_string_literal: true

json.array! @hardpoints,
  partial: "api/v1/hardpoints/base",
  as: :hardpoint,
  # The build row is in the key because the facts now come from it: a build
  # landing under an untouched slot leaves the row's own `updated_at` alone, so
  # keying on the slot alone would serve the previous build's loadout. For a
  # matrix slot `facts` is the slot itself and this collapses back to one entry.
  cached: ->(hardpoint) {
    ["v2", hardpoint, hardpoint.facts, hardpoint.facts.component, Manufacturer.artwork_version]
  }
