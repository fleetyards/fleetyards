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
if outfit.character_face
  json.character_face do
    json.id outfit.character_face.id
    json.token outfit.character_face.token
    json.name outfit.character_face.name
    json.body outfit.character_face.body
  end
else
  json.character_face nil
end
json.partial! "api/shared/dates", record: outfit
