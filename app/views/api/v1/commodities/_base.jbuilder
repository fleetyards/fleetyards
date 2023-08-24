# frozen_string_literal: true

json.id commodity.id
json.name commodity.name
json.slug commodity.slug

json.availability do
  json.listed_at do
    json.array! commodity.listed_at, partial: "api/v1/shop_commodities/base", as: :shop_commodity
  end
  json.bought_at do
    json.array! commodity.bought_at, partial: "api/v1/shop_commodities/base", as: :shop_commodity
  end
  json.sold_at do
    json.array! commodity.sold_at, partial: "api/v1/shop_commodities/base", as: :shop_commodity
  end
end

json.media({})
json.media do
  json.store_image do
    json.partial! "api/v1/shared/media_image", media_image: commodity.store_image
  end
end

json.type commodity.commodity_type
json.type_label commodity.commodity_type_label

json.partial! "api/shared/dates", record: commodity

# DEPRECATED
json.store_image commodity.store_image.url
json.store_image_is_fallback commodity.store_image.identifier.nil?
json.store_image_large commodity.store_image.large.url
json.store_image_medium commodity.store_image.medium.url
json.store_image_small commodity.store_image.small.url
