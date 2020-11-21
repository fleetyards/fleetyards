# frozen_string_literal: true

json.id model_module.id
json.name model_module.name
json.description model_module.description
json.pledge_price model_module.pledge_price
json.store_image model_module.store_image.url
json.store_image_store model_module.store_image.store.url
json.store_image_medium model_module.store_image.medium.url
json.store_image_small model_module.store_image.small.url
json.production_status model_module.production_status
json.sold_at do
  json.array! model_module.sold_at, partial: 'api/v1/shop_commodities/base', as: :shop_commodity
end
json.bought_at do
  json.array! model_module.bought_at, partial: 'api/v1/shop_commodities/base', as: :shop_commodity
end
