# frozen_string_literal: true

json.cache! ['v1', model_module_package] do
  json.partial! 'api/v1/model_module_packages/base', model_module_package: model_module_package
  json.partial! 'api/shared/dates', record: model_module_package
end
