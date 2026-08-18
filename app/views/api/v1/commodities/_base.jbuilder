# frozen_string_literal: true

json.id commodity.id
json.name commodity.name
json.slug commodity.slug
json.commodity_type commodity.commodity_type
json.description commodity.description

json.store_image do
  json.partial! "api/v1/shared/file", record: commodity, attr: :store_image
end

json.availability do
  json.bought_at do
    json.array! commodity.bought_at, partial: "api/v1/item_prices/base", as: :item_price
  end
  json.sold_at do
    json.array! commodity.sold_at, partial: "api/v1/item_prices/base", as: :item_price
  end
end

json.partial! "api/shared/dates", record: commodity
