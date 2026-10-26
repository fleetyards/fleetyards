# frozen_string_literal: true

cart_item = line.cart_item

json.id cart_item.id
json.quantity cart_item.quantity
json.item do
  json.id cart_item.item_id
  json.type cart_item.item_type
  json.name line.item.name
  json.slug line.item.try(:slug)
  json.listed line.item.try(:listed?) != false
  json.counted line.item.try(:counted?) || false
end
json.available line.available?
json.pinned line.pinned?
json.unit_price line.unit_price&.to_f
json.total line.total&.to_f
if line.price
  json.price do
    json.partial! "api/v1/item_prices/base", item_price: line.price
  end
end
json.offers line.offers, partial: "api/v1/item_prices/base", as: :item_price
json.partial! "api/shared/dates", record: cart_item
