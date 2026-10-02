# frozen_string_literal: true

json.id @shop.id
json.name @shop.name
json.slug @shop.slug

if @shop.image.attached?
  json.image do
    json.partial! "api/v1/shared/file", record: @shop, attr: :image
  end
end

json.location do
  json.partial! "api/v1/locations/link", location: @shop.location
end

json.ancestors @ancestors do |ancestor|
  json.partial! "api/v1/locations/link", location: ancestor
end

if @shop.location.system
  json.system do
    json.partial! "api/v1/locations/link", location: @shop.location.system
  end
else
  json.system nil
end

json.items_count @items.size
json.categories ::Shops::Categories.for(@items.map(&:item)) do |category|
  json.partial! "api/v1/shops/category", category:
end

json.items @items do |entry|
  json.id entry.item.id
  json.name entry.item.name
  json.slug entry.item.slug
  json.item_type entry.item.class.name
  category = ::Shops::Categories.key_of(entry.item)
  json.category category
  json.category_label ::Shops::Categories.label_of(entry.item, category)

  json.prices entry.prices do |price|
    json.price_type price.price_type
    json.price price.price.to_f
    json.time_range price.time_range
  end
end

json.created_at @shop.created_at
json.updated_at @shop.updated_at
