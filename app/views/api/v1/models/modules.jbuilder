# frozen_string_literal: true

json.items do
  json.array! @model_modules do |model_module|
    # Prices too, the module's and its hardpoints' components': a price sync
    # touches neither the module nor its slots. The locale, because the
    # hardpoints' components carry translated labels.
    json.cache! [
      "v6", I18n.locale, model_module, ::ScData::Source.current, ItemPrice.cache_key_for("Component", "ModelModule"), Manufacturer.artwork_version
    ] do
      json.partial!("api/v1/model_modules/base", model_module:)
    end
    json.slot @module_slots[model_module.id]
    json.stock @stock_module_ids.include?(model_module.id)
  end
end
# Outside the cached items: which parts a recipe makes follows the build being
# served, not the module rows.
json.craftable_component_ids @craftable_module_component_ids.to_a
json.partial! "api/shared/meta", result: @model_modules
