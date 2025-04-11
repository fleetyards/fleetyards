# frozen_string_literal: true

json.id model_module.id
json.name model_module.name

json.availability do
  json.bought_at do
    json.array! model_module.bought_at, partial: "api/v1/item_prices/base", as: :item_price
  end
  json.sold_at do
    json.array! model_module.sold_at, partial: "api/v1/item_prices/base", as: :item_price
  end
end

json.description model_module.description
json.has_store_image model_module.store_image.present?

json.media({})
json.media do
  json.store_image do
    json.partial! "api/v1/shared/view_image", record: model_module, attr: :new_store_image, old_attr: :store_image, width: model_module.store_image_width, height: model_module.store_image_height
  end
end

json.model do
  json.partial! "api/v1/models/base", model: model_paint.model
end

json.pledge_price model_module.pledge_price
json.production_status model_module.production_status

json.partial! "api/shared/dates", record: model_module
