# frozen_string_literal: true

if fleet_contract_item.item.present?
  json.item do
    json.id fleet_contract_item.item_id
    json.type fleet_contract_item.item_type
    json.name fleet_contract_item.item.name
    json.slug fleet_contract_item.item.try(:slug)
    json.counted fleet_contract_item.item.try(:counted?) || false
  end
else
  json.item nil
end
