# frozen_string_literal: true

json.id equipment.id
json.name equipment.name
json.slug equipment.slug
json.description equipment.description

json.equipment_type equipment.equipment_type
json.item_type equipment.item_type
json.sub_type equipment.sub_type
json.weapon_class equipment.weapon_class

json.size equipment.size
json.grade equipment.grade
json.rate_of_fire equipment.rate_of_fire&.to_f
json.range equipment.range&.to_f
json.storage equipment.storage&.to_f

if equipment.manufacturer.present?
  json.manufacturer do
    json.partial! "api/v1/manufacturers/base", manufacturer: equipment.manufacturer
  end
end

json.availability do
  json.bought_at do
    json.array! equipment.bought_at, partial: "api/v1/item_prices/base", as: :item_price
  end
  json.sold_at do
    json.array! equipment.sold_at, partial: "api/v1/item_prices/base", as: :item_price
  end
end

json.partial! "api/shared/dates", record: equipment
