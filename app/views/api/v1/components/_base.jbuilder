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

# What a port must offer to take this item -- half the "what fits where"
# answer a catalogue visitor is after.
#
# `tags`, the other half, is deliberately absent: the parser writes the whole
# JSON array as a single string inside the array (`["[\"flightReady\"]"]`) for
# every component in the tree, so exposing it would publish visibly broken
# values. It needs a parser fix and a re-parse, which is its own change.
json.required_tags component.required_tags

# The space an item takes, and how big it is. Clean and consistent across all
# 7,336 rows that carry it.
#
# `ammunition`, `power_connection` and `heat_connection` are **not** emitted.
# They are raw game-file dumps: `heat_connection` alone carries 22 different
# keys across the table, mixing `MaxCoolingRate` with `cooling_rate` in the
# same hash, and `ammunition` nests PascalCase damage types. A public contract
# cannot document that honestly without a parser pass first -- the same
# cleanup #5002 needs for `tags`. The live power figures are in
# `typeData.powerRanges` regardless.
json.inventory_consumption component.inventory_consumption

json.hidden component.hidden

# Not in the build we are on. Until now the API offered a component the
# export had dropped as though it were current.
json.retired component.retired?

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

# Detail only, and optional in the schema, so a list response simply omits it.
# This is the weight the slim weapons endpoint was built to escape -- an
# association hit per component, against a catalogue page of 50.
#
# Narrowed the same way the nested levels are: a component's own ports are
# game-file slots, and one this build no longer describes has to stop being
# listed.
if local_assigns.fetch(:extended, false)
  json.hardpoints do
    json.array! component.hardpoints.in_build, partial: "api/v1/hardpoints/base", as: :hardpoint
  end
end

json.partial! "api/shared/dates", record: component
