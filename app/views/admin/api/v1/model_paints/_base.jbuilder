# frozen_string_literal: true

json.id model_paint.id
json.name model_paint.name
json.slug model_paint.slug

json.availability do
  json.bought_at do
    json.array! model_paint.bought_at, partial: "api/v1/shop_commodities/base", as: :shop_commodity
  end
  json.sold_at do
    json.array! model_paint.sold_at, partial: "api/v1/shop_commodities/base", as: :shop_commodity
  end
end

json.description model_paint.description
json.last_updated_at model_paint.last_updated_at&.utc&.iso8601
json.last_updated_at_label((I18n.l(model_paint.last_updated_at.utc, format: :label) if model_paint.last_updated_at.present?))

json.media({})
json.media do
  json.ignore_nil!
  json.angled_view do
    json.partial! "api/v1/shared/view_image", view_image: model_paint.angled_view, width: model_paint.angled_view_width, height: model_paint.angled_view_height
  end
  json.fleetchart_image model_paint.fleetchart_image.url
  # json.front_view do
  #   json.partial! "api/v1/shared/view_image", view_image: model_paint.front_view, width: model_paint.front_view_width, height: model_paint.front_view_height
  # end
  json.side_view do
    json.partial! "api/v1/shared/view_image", view_image: model_paint.side_view, width: model_paint.side_view_width, height: model_paint.side_view_height
  end
  json.store_image do
    json.partial! "api/v1/shared/media_image", media_image: model_paint.store_image
  end
  json.top_view do
    json.partial! "api/v1/shared/view_image", view_image: model_paint.top_view, width: model_paint.top_view_width, height: model_paint.top_view_height
  end
end

json.name_with_model model_paint.name_with_model
json.rsi_id model_paint.rsi_id
json.rsi_name model_paint.rsi_name
json.rsi_slug model_paint.rsi_slug

json.partial! "api/shared/dates", record: model_paint
