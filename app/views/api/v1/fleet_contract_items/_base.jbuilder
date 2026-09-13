# frozen_string_literal: true

json.id fleet_contract_item.id
json.name fleet_contract_item.name
json.category fleet_contract_item.category
json.unit fleet_contract_item.unit
json.quantity fleet_contract_item.quantity
json.min_quality fleet_contract_item.min_quality
json.position fleet_contract_item.position

if fleet_contract_item.item.present?
  json.item do
    json.id fleet_contract_item.item_id
    json.type fleet_contract_item.item_type
    json.name fleet_contract_item.item.name
    json.slug fleet_contract_item.item.try(:slug)
  end
else
  json.item nil
end

json.partial! "api/shared/dates", record: fleet_contract_item
