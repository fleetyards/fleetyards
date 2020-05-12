# frozen_string_literal: true

json.id model_skin.id
json.name model_skin.name
json.rsi_name model_skin.rsi_name
json.slug model_skin.slug
json.rsi_slug model_skin.rsi_slug
json.description model_skin.description
json.store_image model_skin.store_image.url
json.store_image_medium model_skin.store_image.medium.url
json.store_image_small model_skin.store_image.small.url
json.store_url rsi_store_url(model_skin.store_url)
json.pledge_price((model_skin.pledge_price.to_f if model_skin.pledge_price.present?))
json.last_pledge_price((model_skin.last_pledge_price.to_f if model_skin.last_pledge_price.present?))
json.on_sale model_skin.on_sale
# json.production_status model_skin.production_status
# json.production_note model_skin.production_note
json.rsi_id model_skin.rsi_id
json.last_updated_at model_skin.last_updated_at&.utc&.iso8601
json.last_updated_at_label((I18n.l(model_skin.last_updated_at.utc, format: :label) if model_skin.last_updated_at.present?))
