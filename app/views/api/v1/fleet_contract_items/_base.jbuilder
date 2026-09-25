# frozen_string_literal: true

json.id fleet_contract_item.id
json.name fleet_contract_item.name
json.category fleet_contract_item.category
json.unit fleet_contract_item.unit
json.quantity fleet_contract_item.quantity
json.quality fleet_contract_item.quality
json.quality_match fleet_contract_item.quality_match
json.position fleet_contract_item.position

json.partial! "api/v1/fleet_contract_items/item_ref", fleet_contract_item: fleet_contract_item

json.partial! "api/shared/dates", record: fleet_contract_item
