# frozen_string_literal: true

json.cache! ['v1', model_module] do
  json.partial! 'admin/api/v1/model_modules/base', model_module: model_module
  json.partial! 'api/shared/dates', record: model_module
end
