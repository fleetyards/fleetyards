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

json.created_at @shop.created_at
json.updated_at @shop.updated_at
