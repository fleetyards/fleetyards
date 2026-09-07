# frozen_string_literal: true

# What the build in force says about this slot. `hardpoint` still answers for
# what identifies it -- the name, the source, the matrix key -- while everything
# a build has an opinion about comes from `facts`, which is the build row or the
# row itself for a matrix slot.
facts = hardpoint.facts

json.id hardpoint.id
json.name hardpoint.sc_name

json.group_key facts.group_key
json.matrix_key hardpoint.matrix_key

json.group facts.group
json.source hardpoint.source

json.min_size facts.min_size
json.max_size facts.max_size

json.types facts.types

json.category facts.category

json.details hardpoint.details

json.component do
  json.partial! "api/v1/components/base", component: facts.component if facts.component.present?
end

# Only the children this build describes. A slot the build dropped keeps its row
# once the cleanup stops destroying, and a port that is no longer on the ship has
# to stop being listed rather than be described from a build ago.
json.hardpoints do
  json.array! hardpoint.hardpoints.in_build, partial: "api/v1/hardpoints/base", as: :hardpoint
end

json.partial! "api/shared/dates", record: hardpoint
