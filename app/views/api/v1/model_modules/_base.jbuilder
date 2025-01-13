# frozen_string_literal: true

json.id model_module.id
json.name model_module.name
json.slug model_module.slug

json.description model_module.description

json.sc_key model_module.sc_key

json.metrics({})
json.metrics do
  json.cargo model_module.cargo.to_f
end

json.availability do
  json.bought_at do
    json.array! model_module.bought_at, partial: "api/v1/item_prices/base", as: :item_price
  end
  json.sold_at do
    json.array! model_module.sold_at, partial: "api/v1/item_prices/base", as: :item_price
  end
end

json.media({})
json.media do
  json.store_image do
    json.partial! "api/v1/shared/media_image", media_image: model_module.store_image
  end
end

json.pledge_price model_module.pledge_price
json.production_status model_module.production_status

json.manufacturer do
  json.null! if model_module.manufacturer.blank?
  json.partial! "api/v1/manufacturers/base", manufacturer: model_module.manufacturer if model_module.manufacturer.present?
end

json.hardpoints do
  json.array! model_module.hardpoints, partial: "api/v1/hardpoints/hardpoint", as: :hardpoint
end

json.partial! "api/shared/dates", record: model_module
