# frozen_string_literal: true

json.items do
  json.array! @model_modules, partial: "api/v1/model_modules/minimal", as: :model_module
end
json.partial! "api/shared/meta", result: @model_modules
