# frozen_string_literal: true

# What the build in force says about this slot. `hardpoint` answers for what
# identifies it -- the name, the parent, the source -- while everything a build
# has an opinion about comes from `facts`, which is the build row or the row
# itself for a matrix slot.
facts = hardpoint.facts

json.id hardpoint.id
json.name hardpoint.sc_name

json.parent_id hardpoint.parent_id
json.parent_type hardpoint.parent_type

# Which half this is, and therefore whether an admin may change it: the loader
# owns `game_files` and rewrites it on every load, the matrix half is curated.
# The frontend needs this to decide what to offer, so it is not just a label.
json.source hardpoint.source
json.editable hardpoint.ship_matrix?

# Not in the build we are on -- a port the loadout no longer has. Only ever true
# for the game-files half.
json.retired hardpoint.retired?

json.group facts.group
json.category facts.category
json.group_key facts.group_key
json.matrix_key hardpoint.matrix_key

json.min_size facts.min_size
json.max_size facts.max_size
json.types facts.types
json.port_tags facts.port_tags
json.required_tags facts.required_tags
json.flags facts.flags

json.details hardpoint.details

json.component do
  json.partial! "api/v1/components/base", component: facts.component if facts.component.present?
end
json.component nil if facts.component.blank?

# The nested slots, which is what a loadout is. Every child the build describes,
# rendered the same way -- the previous version of this view emitted a flat
# `loadouts` array shaped like the legacy table's, with a `model_hardpoint_id`
# nothing read.
json.hardpoints do
  json.array! hardpoint.hardpoints.in_build, partial: "admin/api/v1/hardpoints/base", as: :hardpoint
end

json.partial! "api/shared/dates", record: hardpoint
