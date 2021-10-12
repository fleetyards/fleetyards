# frozen_string_literal: true

json.id component.id
json.name component.name
json.slug component.slug
json.grade component.grade
json.class component.component_class
json.size component.size
json.type component.item_type
json.type_label component.item_type_label
json.item_class component.item_class
json.item_class_label component.item_class_label
json.tracking_signal component.tracking_signal
json.tracking_signal_label component.tracking_signal_label
json.store_image_is_fallback component.store_image.identifier.nil?
json.store_image component.store_image.url
json.store_image_medium component.store_image.medium.url
json.store_image_small component.store_image.small.url
json.sold_at do
  json.array! component.sold_at, partial: 'api/v1/shop_commodities/base', as: :shop_commodity
end
json.bought_at do
  json.array! component.bought_at, partial: 'api/v1/shop_commodities/base', as: :shop_commodity
end
json.listed_at do
  json.array! component.listed_at, partial: 'api/v1/shop_commodities/base', as: :shop_commodity
end
json.manufacturer do
  json.null! if component.manufacturer.blank?
  json.partial! 'api/v1/manufacturers/base', manufacturer: component.manufacturer if component.manufacturer.present?
end
