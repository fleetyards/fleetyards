# frozen_string_literal: true

json.id component.id
json.name component.name
json.slug component.slug
json.hidden component.hidden

json.availability do
  json.bought_at do
    json.array! component.bought_at, partial: "api/v1/item_prices/base", as: :item_price
  end
  json.sold_at do
    json.array! component.sold_at, partial: "api/v1/item_prices/base", as: :item_price
  end
end

json.class component.component_class
json.grade component.grade
json.item_class component.item_class
json.item_class_label component.item_class_label

json.manufacturer do
  json.null! if component.manufacturer.blank?
  json.partial! "api/v1/manufacturers/base", manufacturer: component.manufacturer if component.manufacturer.present?
end

json.media({})
json.media do
  json.store_image do
    json.partial! "api/v1/shared/view_image", record: component, attr: :new_store_image, old_attr: :store_image, width: component.store_image_width, height: component.store_image_height
  end
end

json.size component.size
json.tracking_signal component.tracking_signal
json.tracking_signal_label component.tracking_signal_label
json.type component.item_type
json.type_label component.item_type_label

json.partial! "api/shared/dates", record: component
