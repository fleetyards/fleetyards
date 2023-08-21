# frozen_string_literal: true

json.id model_module.id
json.name model_module.name

json.availability do
  json.bought_at do
    json.array! model_module.bought_at, partial: "api/v1/shop_commodities/base", as: :shop_commodity
  end
  json.sold_at do
    json.array! model_module.sold_at, partial: "api/v1/shop_commodities/base", as: :shop_commodity
  end
end

json.description model_module.description
json.has_store_image model_module.store_image.present?

json.media({})
json.media do
  json.ignore_nil!
  json.store_image do
    json.partial! "api/v1/shared/media_image", media_image: model_module.store_image
  end
end

json.pledge_price model_module.pledge_price
json.production_status model_module.production_status

json.store_image model_module.store_image.url
json.store_image_large model_module.store_image.large.url
json.store_image_medium model_module.store_image.medium.url
json.store_image_small model_module.store_image.small.url

json.manufacturer do
  json.null! if model_module.manufacturer.blank?
  json.partial! "api/v1/manufacturers/base", manufacturer: model_module.manufacturer if model_module.manufacturer.present?
end

json.partial! "api/shared/dates", record: model_module
