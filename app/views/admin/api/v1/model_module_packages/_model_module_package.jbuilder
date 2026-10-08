# frozen_string_literal: true

# The embedded model is keyed too: a measurement changes it without touching
# the package. So are component prices, which the modules' hardpoints render.
json.cache! [
  "v4", model_module_package, model_module_package.model, ItemPrice.cache_key_for("Component"),
  Manufacturer.artwork_version
] do
  json.partial!("admin/api/v1/model_module_packages/base", model_module_package:)
end
