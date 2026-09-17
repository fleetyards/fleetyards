# frozen_string_literal: true

json.id blueprint.id
json.name blueprint.name
json.slug blueprint.slug

json.sc_key blueprint.sc_key
json.sc_ref blueprint.sc_ref

# Seconds. The game states it partitioned into days/hours/minutes/seconds and
# nothing in the export takes a day, so one integer loses nothing.
json.craft_time blueprint.craft_time

# How many of the slots below a single craft fills, which is not always all of
# them: 62 recipes take one, 442 two, 1072 three and 31 four.
json.slot_count blueprint.slot_count

json.retired blueprint.retired?

# Nothing in the export says where 901 of the 1607 recipes come from. Stated
# rather than left to an empty array, which reads as a gap in our data rather
# than as a gap in the game's.
json.source_unknown blueprint.source_unknown?

# What the recipe makes. 5 of 1607 resolve to no catalogue row at all -- four
# mission carryables that are in no catalogue, and one entity class present in
# no file in the export -- so this is null rather than guaranteed.
if blueprint.craftable.present?
  json.craftable do
    json.type blueprint.craftable_type
    json.id blueprint.craftable.id
    json.name blueprint.craftable.name
    json.slug blueprint.craftable.slug
  end
end

json.created_at blueprint.created_at
json.updated_at blueprint.updated_at
