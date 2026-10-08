# frozen_string_literal: true

json.items do
  json.array! @model_modules do |model_module|
    # Prices too, the module's and its hardpoints' components': a price sync
    # touches neither the module nor its slots.
    json.cache! [
      "v4", model_module, ::ScData::Source.current, ItemPrice.cache_key_for("Component", "ModelModule"), Manufacturer.artwork_version
    ] do
      json.partial!("api/v1/model_modules/base", model_module:)
    end
    json.slot @module_slots[model_module.id]
  end
end
json.partial! "api/shared/meta", result: @model_modules
