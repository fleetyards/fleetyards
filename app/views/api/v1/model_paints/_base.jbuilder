# frozen_string_literal: true

json.id model_paint.id
json.name model_paint.name
json.slug model_paint.slug
json.rsi_name model_paint.rsi_name
json.rsi_slug model_paint.rsi_slug
json.description model_paint.description
json.store_image model_paint.store_image.url
json.store_image_medium model_paint.store_image.medium.url
json.store_image_small model_paint.store_image.small.url
json.last_updated_at model_paint.last_updated_at&.utc&.iso8601
json.last_updated_at_label((I18n.l(model_paint.last_updated_at.utc, format: :label) if model_paint.last_updated_at.present?))
