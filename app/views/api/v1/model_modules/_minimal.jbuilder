# frozen_string_literal: true

json.cache! ['v1', model_module] do
  json.partial!('api/v1/model_modules/base', model_module:)
  json.manufacturer do
    json.null! if model_module.manufacturer.blank?
    json.partial! 'api/v1/manufacturers/base', manufacturer: model_module.manufacturer if model_module.manufacturer.present?
  end
  json.partial! 'api/shared/dates', record: model_module
end
