# frozen_string_literal: true

json.id equipment.id
json.name equipment.name
json.slug equipment.slug

json.availability do
  json.bought_at do
    json.array! equipment.bought_at, partial: "api/v1/shop_commodities/base", as: :shop_commodity
  end
  json.listed_at do
    json.array! equipment.listed_at, partial: "api/v1/shop_commodities/base", as: :shop_commodity
  end
  json.sold_at do
    json.array! equipment.sold_at, partial: "api/v1/shop_commodities/base", as: :shop_commodity
  end
end

# json.damage equipment.damage
json.backpack_compatibility equipment.backpack_compatibility_label
json.core_compatibility equipment.core_compatibility_label
json.damage_reduction equipment.damage_reduction
json.description equipment.description if equipment.description.present?
json.extras equipment.extras
json.grade equipment.grade
json.item_type equipment.item_type
json.item_type_label equipment.item_type_label

json.manufacturer do
  json.null! if equipment.manufacturer.blank?
  json.partial! "api/v1/manufacturers/base", manufacturer: equipment.manufacturer if equipment.manufacturer.present?
end

json.media({})
json.media do
  json.ignore_nil!
  json.store_image do
    json.partial! "api/v1/shared/media_image", media_image: equipment.store_image
  end
end

json.range equipment.range
json.rate_of_fire equipment.rate_of_fire
json.size equipment.size
json.slot equipment.slot
json.slot_label equipment.slot_label
json.storage equipment.storage
json.temperature_rating equipment.temperature_rating
json.type equipment.equipment_type
json.type_label equipment.equipment_type_label
json.volume equipment.volume
json.weapon_class equipment.weapon_class
json.weapon_class_label equipment.weapon_class_label

json.partial! "api/shared/dates", record: equipment

# DEPRECATED
json.store_image equipment.store_image.url
json.store_image_is_fallback equipment.store_image.identifier.nil?
json.store_image_large equipment.store_image.large.url
json.store_image_medium equipment.store_image.medium.url
json.store_image_small equipment.store_image.small.url
