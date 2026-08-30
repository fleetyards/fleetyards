# frozen_string_literal: true

json.id inventory.id
json.fleet_id inventory.fleet_id
json.name inventory.name
json.slug inventory.slug
json.description inventory.description
json.location inventory.location
json.visibility inventory.visibility
json.manager_id inventory.managed_by
json.manager_username inventory.manager&.username
json.items_count inventory.fleet_inventory_items.size

json.partial! "api/shared/dates", record: inventory
