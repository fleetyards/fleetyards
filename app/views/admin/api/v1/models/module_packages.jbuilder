# frozen_string_literal: true

json.items do
  json.array! @model_module_packages, partial: "api/v1/model_module_packages/model_module_package", as: :module_package
end
json.partial! "api/shared/meta", result: @model_module_packages
