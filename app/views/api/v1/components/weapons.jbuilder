# frozen_string_literal: true

json.array! @weapons do |weapon|
  json.id weapon.id
  json.name weapon.name
  json.slug weapon.slug
  json.size weapon.size
  json.manufacturer_code weapon.manufacturer&.code
  json.beam weapon.type_data&.dig("beam") || false
  json.weapon_class weapon.type_data&.dig("weapon_class")
  json.pellets_per_shot (weapon.type_data&.dig("pellets_per_shot") || 1).to_i

  damage = weapon.type_data&.dig("damage_per_shot") || {}

  json.damage_per_shot do
    json.physical damage["physical"].to_f
    json.energy damage["energy"].to_f
    json.distortion damage["distortion"].to_f
    json.thermal damage["thermal"].to_f
  end
end
