# frozen_string_literal: true

json.id equipment.id
json.name equipment.name
json.slug equipment.slug
json.description equipment.description
json.grade equipment.grade
json.size equipment.size
json.type equipment.equipment_type
json.type_label equipment.equipment_type_label
json.item_type equipment.item_type
json.item_type_label equipment.item_type_label
json.weapon_class equipment.weapon_class
json.weapon_class_label equipment.weapon_class_label
json.slot equipment.slot
json.slot_label equipment.slot_label
json.damage_reduction equipment.damage_reduction
# json.damage equipment.damage
json.rate_of_fire equipment.rate_of_fire
json.range equipment.range
json.extras equipment.extras
json.storage equipment.storage
json.store_image_is_fallback equipment.store_image.identifier.nil?
json.store_image equipment.store_image.url
json.store_image_medium equipment.store_image.medium.url
json.store_image_small equipment.store_image.small.url
json.sold_at do
  json.array! equipment.sold_at, partial: 'api/v1/shop_commodities/base', as: :shop_commodity
end
json.bought_at do
  json.array! equipment.bought_at, partial: 'api/v1/shop_commodities/base', as: :shop_commodity
end
json.listed_at do
  json.array! equipment.listed_at, partial: 'api/v1/shop_commodities/base', as: :shop_commodity
end
json.manufacturer do
  json.null! if equipment.manufacturer.blank?
  json.partial! 'api/v1/manufacturers/base', manufacturer: equipment.manufacturer if equipment.manufacturer.present?
end
