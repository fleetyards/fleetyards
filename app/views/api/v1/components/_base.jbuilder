# frozen_string_literal: true

json.id component.id
json.name component.name
json.slug component.slug

json.sc_key component.sc_key
json.sc_ref component.sc_ref

json.category component.category
json.type component.component_type
json.sub_type component.component_sub_type

json.availability do
  json.bought_at do
    json.array! component.bought_at, partial: "api/v1/item_prices/base", as: :item_price
  end
  json.sold_at do
    json.array! component.sold_at, partial: "api/v1/item_prices/base", as: :item_price
  end
end

json.grade component.grade
json.grade_label component.grade_label
json.size component.size
json.item_class component.item_class
json.item_class_label component.item_class_label

json.type_data component.type_data

json.hardpoints do
  json.array! component.hardpoints, partial: "api/v1/hardpoints/base", as: :hardpoint
end

json.manufacturer do
  json.null! if component.manufacturer.blank?
  json.partial! "api/v1/manufacturers/base", manufacturer: component.manufacturer if component.manufacturer.present?
end

json.media({})
json.media do
  json.store_image do
    json.partial! "api/v1/shared/media_image", media_image: component.store_image
  end
end

json.partial! "api/shared/dates", record: component
