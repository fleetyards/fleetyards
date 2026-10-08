# frozen_string_literal: true

# The embedded models are keyed too, by their newest change: a measurement
# changes a model without touching the module. So are component prices, which
# the hardpoints render and a price sync changes without touching either.
json.cache! [
  "v4", model_module, model_module.models.maximum(:updated_at), ItemPrice.cache_key_for("Component"),
  Manufacturer.artwork_version
] do
  json.partial!("admin/api/v1/model_modules/base", model_module:)
end
