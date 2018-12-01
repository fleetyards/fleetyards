# frozen_string_literal: true

json.id model_module.id
json.name model_module.name
json.description model_module.description
json.store_image model_module.store_image.url
json.store_image_medium model_module.store_image.medium.url
json.store_image_thumb model_module.store_image.small.url
json.production_status model_module.production_status
json.manufacturer do
  json.manufacturer nil if model_module.manufacturer.blank?
  json.partial! 'api/v1/manufacturers/base', manufacturer: model_module.manufacturer if model_module.manufacturer.present?
end
