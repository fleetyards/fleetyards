# frozen_string_literal: true

json.id item.id
json.fleet_inventory_id item.fleet_inventory_id
json.name item.name
json.category item.category
json.entry_type item.entry_type
json.unit item.unit
json.quantity item.quantity.to_s
json.quality item.quality
json.notes item.notes
json.item_id item.item_id
json.item_type item.item_type

json.partial! "api/shared/dates", record: item
