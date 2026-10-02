# frozen_string_literal: true

json.id @shop.id
json.name @shop.name
json.slug @shop.slug
json.items_count @shop.item_prices.distinct.count(:item_id)

if @shop.image.attached?
  json.image do
    json.partial! "api/v1/shared/file", record: @shop, attr: :image
  end
end

json.location do
  json.partial! "api/v1/locations/link", location: @shop.location
end

json.created_at @shop.created_at
json.updated_at @shop.updated_at
