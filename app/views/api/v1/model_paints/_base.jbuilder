# frozen_string_literal: true

json.id model_paint.id
json.name model_paint.name
json.slug model_paint.slug
json.name_with_model model_paint.name_with_model
json.rsi_name model_paint.rsi_name
json.rsi_slug model_paint.rsi_slug
json.rsi_id model_paint.rsi_id
json.description model_paint.description
json.has_store_image model_paint.store_image.present?
json.store_image model_paint.store_image.url
json.store_image_large model_paint.store_image.large.url
json.store_image_medium model_paint.store_image.medium.url
json.store_image_small model_paint.store_image.small.url
json.fleetchart_image model_paint.fleetchart_image.url
json.top_view model_paint.top_view.url
json.side_view model_paint.side_view.url
json.last_updated_at model_paint.last_updated_at&.utc&.iso8601
json.last_updated_at_label((I18n.l(model_paint.last_updated_at.utc, format: :label) if model_paint.last_updated_at.present?))
json.sold_at do
  json.array! model_paint.sold_at, partial: 'api/v1/shop_commodities/base', as: :shop_commodity
end
json.bought_at do
  json.array! model_paint.bought_at, partial: 'api/v1/shop_commodities/base', as: :shop_commodity
end
