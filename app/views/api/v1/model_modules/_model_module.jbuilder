# frozen_string_literal: true

# The module's prices and its hardpoints' component prices both render here,
# and a price sync changes them without touching the module.
json.cache! [
  "v4", I18n.locale, model_module, ::ScData::Source.current, ItemPrice.cache_key_for("Component", "ModelModule"), Manufacturer.artwork_version
] do
  json.partial!("api/v1/model_modules/base", model_module:)
end
