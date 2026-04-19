# frozen_string_literal: true

json.id model_module.id
json.name model_module.name
json.active model_module.active
json.hidden model_module.hidden

json.availability do
  json.bought_at do
    json.array! model_module.bought_at, partial: "api/v1/item_prices/base", as: :item_price
  end
  json.sold_at do
    json.array! model_module.sold_at, partial: "api/v1/item_prices/base", as: :item_price
  end
end

json.description model_module.description
json.sc_key model_module.sc_key
json.has_store_image model_module.store_image.attached?

json.media({})
json.media do
  json.store_image do
    json.partial! "api/v1/shared/file", record: model_module, attr: :store_image
  end
end

if model_module.models.any?
  json.model do
    json.partial! "admin/api/v1/models/base", model: model_module.models.first
  end
end

json.models do
  json.array! model_module.models, partial: "admin/api/v1/models/base", as: :model
end

json.price model_module.price
json.pledge_price model_module.pledge_price
json.production_status model_module.production_status

if model_module.manufacturer.present?
  json.manufacturer do
    json.partial! "api/v1/manufacturers/base", manufacturer: model_module.manufacturer
  end
end

json.partial! "api/shared/dates", record: model_module
