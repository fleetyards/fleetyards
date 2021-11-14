# frozen_string_literal: true

json.id model_module_package.id
json.name model_module_package.name
json.description model_module_package.description
json.pledge_price model_module_package.pledge_price
json.has_store_image model_module_package.store_image.present?
json.store_image model_module_package.store_image.url
json.store_image_large model_module_package.store_image.large.url
json.store_image_medium model_module_package.store_image.medium.url
json.store_image_small model_module_package.store_image.small.url
json.modules do
  json.array! model_module_package.model_modules, partial: 'api/v1/model_modules/base', as: :model_module
end
