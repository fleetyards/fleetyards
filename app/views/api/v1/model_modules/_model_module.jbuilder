# frozen_string_literal: true

# The hardpoints render their components' prices, which a price sync changes
# without touching the module.
json.cache! [
  "v3", model_module, ::ScData::Source.current, ItemPrice.cache_key_for("Component"), Manufacturer.artwork_version
] do
  json.partial!("api/v1/model_modules/base", model_module:)
end
