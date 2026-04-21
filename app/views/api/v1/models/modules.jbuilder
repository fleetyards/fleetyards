# frozen_string_literal: true

json.items do
  json.array! @model_modules do |model_module|
    json.partial!("api/v1/model_modules/base", model_module:)
    json.slot @module_slots[model_module.id]
  end
end
json.partial! "api/shared/meta", result: @model_modules
