# frozen_string_literal: true

json.id inventory.id
json.holder_id inventory.holder_id
json.holder_type inventory.holder_type
json.name inventory.name
json.slug inventory.slug
json.description inventory.description
json.location inventory.location
json.vehicle_id inventory.vehicle_id
json.items_count inventory.inventory_items.size

json.partial! "api/shared/dates", record: inventory
