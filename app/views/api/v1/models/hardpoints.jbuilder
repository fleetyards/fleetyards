# frozen_string_literal: true

json.array! @hardpoints,
  partial: "api/v1/hardpoints/base",
  as: :hardpoint,
  # The source is in the key because the facts come from the build in force, and
  # the build row as well: a build landing under an untouched slot leaves the
  # row's own `updated_at` alone, so keying on the slot alone would serve the
  # previous build's loadout. For a matrix slot `facts` is the slot itself and
  # that half collapses back to one entry per source.
  cached: ->(hardpoint) {
    ["v2", hardpoint, ::ScData::Source.current, hardpoint.facts, hardpoint.facts.component, Manufacturer.artwork_version]
  }
