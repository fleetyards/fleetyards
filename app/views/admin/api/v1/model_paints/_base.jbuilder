# frozen_string_literal: true

json.id model_paint.id
json.name model_paint.name
json.slug model_paint.slug
json.hidden model_paint.hidden
json.active model_paint.active

json.availability do
  json.bought_at do
    json.array! model_paint.bought_at, partial: "api/v1/item_prices/base", as: :item_price
  end
  json.sold_at do
    json.array! model_paint.sold_at, partial: "api/v1/item_prices/base", as: :item_price
  end
end

json.description model_paint.description
json.last_updated_at model_paint.last_updated_at&.utc&.iso8601
json.last_updated_at_label((I18n.l(model_paint.last_updated_at.utc, format: :label) if model_paint.last_updated_at.present?))

json.media({})
json.media do
  json.angled_view do
    json.partial! "api/v1/shared/file", record: model_paint, attr: :angled_view
  end
  json.fleetchart_image(model_paint.fleetchart_image.attached? ? rails_blob_url(model_paint.fleetchart_image) : nil)
  json.front_view do
    json.partial! "api/v1/shared/file", record: model_paint, attr: :front_view
  end
  json.side_view do
    json.partial! "api/v1/shared/file", record: model_paint, attr: :side_view
  end
  json.store_image do
    json.partial! "api/v1/shared/file", record: model_paint, attr: :store_image
  end
  json.top_view do
    json.partial! "api/v1/shared/file", record: model_paint, attr: :top_view
  end
end

json.model do
  json.partial! "admin/api/v1/models/base", model: model_paint.model
end

json.name_with_model model_paint.name_with_model
json.rsi_id model_paint.rsi_id
json.rsi_name model_paint.rsi_name
json.rsi_slug model_paint.rsi_slug

json.partial! "api/shared/dates", record: model_paint
