# frozen_string_literal: true

# The modules' hardpoints render component prices, which a price sync changes
# without touching the package.
json.cache! [
  "v3", module_package, ::ScData::Source.current, ItemPrice.cache_key_for("Component"), Manufacturer.artwork_version
] do
  json.partial!("api/v1/model_module_packages/base", module_package:)
end
