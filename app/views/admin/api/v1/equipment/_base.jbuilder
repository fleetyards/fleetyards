# frozen_string_literal: true

json.id equipment.id
json.name equipment.name
json.slug equipment.slug
json.description equipment.description
json.hidden equipment.hidden

json.equipment_type equipment.equipment_type
json.item_type equipment.item_type
json.sub_type equipment.sub_type
json.weapon_class equipment.weapon_class

json.slot equipment.slot
json.size equipment.size
json.grade equipment.grade
json.rate_of_fire equipment.rate_of_fire&.to_f
json.range equipment.range&.to_f
json.storage equipment.storage&.to_f

json.volume equipment.volume&.to_f
json.volume_dimensions equipment.volume_dimensions

json.damage_reduction equipment.damage_reduction&.to_f
json.temperature_rating equipment.temperature_rating
json.radiation_protection equipment.radiation_protection&.to_f
json.radiation_scrub_rate equipment.radiation_scrub_rate&.to_f
json.g_force_tolerance equipment.g_force_tolerance&.to_f
json.core_compatibility equipment.core_compatibility
json.backpack_compatibility equipment.backpack_compatibility

json.manufacturer do
  json.null! if equipment.manufacturer.blank?
  json.partial! "admin/api/v1/manufacturers/base", manufacturer: equipment.manufacturer if equipment.manufacturer.present?
end

json.availability do
  json.bought_at do
    json.array! equipment.bought_at, partial: "api/v1/item_prices/base", as: :item_price
  end
  json.sold_at do
    json.array! equipment.sold_at, partial: "api/v1/item_prices/base", as: :item_price
  end
end

json.buy_price equipment.buy_price&.to_f
json.sell_price equipment.sell_price&.to_f

json.store_image do
  json.partial! "api/v1/shared/file", record: equipment, attr: :store_image
end

# Carried on the admin payload only: the loader writes these and an admin has to
# be able to tell a hand-made row from one the export owns.
json.sc_key equipment.sc_key
json.sc_ref equipment.sc_ref
json.version equipment.version

json.partial! "api/shared/dates", record: equipment
