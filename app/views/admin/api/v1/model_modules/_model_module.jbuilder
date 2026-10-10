# frozen_string_literal: true

# The embedded models are keyed too, by their newest change: a measurement
# changes a model without touching the module. So are the module's prices and
# its hardpoints' component prices, which a price sync changes without touching
# either.
json.cache! [
  "v5", model_module, model_module.models.maximum(:updated_at), ItemPrice.cache_key_for("Component", "ModelModule"),
  Manufacturer.artwork_version
] do
  json.partial!("admin/api/v1/model_modules/base", model_module:)
end
