# frozen_string_literal: true

json.id model_skin.id
json.name model_skin.name
json.slug model_skin.slug
json.rsi_name model_skin.rsi_name
json.rsi_slug model_skin.rsi_slug
json.description model_skin.description
json.store_image model_skin.store_image.url
json.store_image_medium model_skin.store_image.medium.url
json.store_image_small model_skin.store_image.small.url
json.last_updated_at model_skin.last_updated_at&.utc&.iso8601
json.last_updated_at_label((I18n.l(model_skin.last_updated_at.utc, format: :label) if model_skin.last_updated_at.present?))
