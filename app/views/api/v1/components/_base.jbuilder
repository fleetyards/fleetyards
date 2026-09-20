# frozen_string_literal: true

json.id component.id
json.name component.name
json.slug component.slug

json.sc_key component.sc_key
json.sc_ref component.sc_ref

json.category component.category
json.type component.component_type
json.sub_type component.component_sub_type

json.grade component.grade
json.grade_label component.grade_label
json.size component.size
json.item_class component.item_class
json.item_class_label component.item_class_label

json.type_data component.type_data

json.description component.description

# The two halves of "what fits where": the tags this item carries, and the
# tags it demands of the port it goes into. A ship's port matches an item by
# naming the same tag, so neither side answers the question alone.
#
# `tags` was held back until the tree carried real values -- the parser used to
# write the whole JSON array as a single string inside the array
# (`["[\"flightReady\"]"]`), and publishing that would have been publishing a
# bug. The parser fix landed in #5007 and the re-parsed tree carries one entry
# per tag.
json.tags component.tags
json.required_tags component.required_tags

# `inventoryConsumption`, `ammunition`, `powerConnection` and `heatConnection`
# are all absent on purpose. The last three are raw game-file dumps --
# `heat_connection` alone carries 22 different keys across the table, mixing
# `MaxCoolingRate` with `cooling_rate` in the same hash -- so no honest schema
# can describe them until the parser gives them consistent keys -- the cleanup
# #5002 tracks. The first is documented as a string it has never been, and
# correcting that type is a breaking change that belongs with #5002 rather than
# here. The live power figures are in `typeData.powerRanges` regardless.

json.hidden component.hidden

# Not in the build we are on. Until now the API offered a component the
# export had dropped as though it were current.
json.retired component.retired?
json.catalogued component.catalogued?

json.manufacturer do
  json.null! if component.manufacturer.blank?
  json.partial! "api/v1/manufacturers/base", manufacturer: component.manufacturer if component.manufacturer.present?
end

json.media({})
json.media do
  json.store_image do
    json.partial! "api/v1/shared/file", record: component, attr: :store_image
  end
end

# Stays in both shapes. It is a required property, so dropping it from the list
# would break every client reading the index -- and it would buy nothing: the
# cache key above already loads `item_prices` for every component, so the rows
# are in memory whether or not they are rendered.
json.availability do
  json.bought_at do
    json.array! component.bought_at, partial: "api/v1/item_prices/base", as: :item_price
  end
  json.sold_at do
    json.array! component.sold_at, partial: "api/v1/item_prices/base", as: :item_price
  end
end

# Emitted by the list as well as the detail page. It is heavy -- an association
# hit per component, which is why the slim weapons endpoint exists -- but the
# index has always carried it, and a client reading `items[].hardpoints` would
# break on its absence. Marking it optional in the schema documents that
# change rather than avoiding it. A lighter list shape is worth having; it
# wants its own endpoint, the way `weapons` got one, rather than quietly
# dropping a field from this one.
#
# Narrowed the same way the nested levels are: a component's own ports are
# game-file slots, and one this build no longer describes has to stop being
# listed.
json.hardpoints do
  json.array! component.hardpoints.in_build, partial: "api/v1/hardpoints/base", as: :hardpoint
end

json.partial! "api/shared/dates", record: component
