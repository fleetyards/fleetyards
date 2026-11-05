# frozen_string_literal: true

json.id outfit.id
json.name outfit.name
json.items outfit.items do |item|
  json.slot item.slot
  json.equipment do
    json.partial! "api/v1/equipment/equipment", equipment: item.equipment
  end
end
json.stored_items outfit.stored_items do |item|
  json.holder item.holder
  json.quantity item.quantity
  json.equipment do
    json.partial! "api/v1/equipment/equipment", equipment: item.equipment
  end
end
json.held_weapon outfit.held_weapon
json.body outfit.body
json.partial! "api/shared/dates", record: outfit
