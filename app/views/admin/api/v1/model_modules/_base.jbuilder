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
json.media do
  json.store_image do
    json.partial! "api/v1/shared/media_image", media_image: model_module.store_image
  end
end
json.pledge_price model_module.pledge_price
json.production_status model_module.production_status
