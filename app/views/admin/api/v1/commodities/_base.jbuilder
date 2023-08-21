# frozen_string_literal: true

json.id commodity.id
json.name commodity.name
json.slug commodity.slug

json.availability do
  json.bought_at do
    json.array! commodity.bought_at, partial: "admin/api/v1/shop_commodities/base", as: :shop_commodity
  end
  json.sold_at do
    json.array! commodity.sold_at, partial: "admin/api/v1/shop_commodities/base", as: :shop_commodity
  end
end

json.media do
  json.store_image do
    json.partial! "api/v1/shared/media_image", media_image: commodity.store_image
  end
end

json.type commodity.commodity_type
json.type_label commodity.commodity_type_label
