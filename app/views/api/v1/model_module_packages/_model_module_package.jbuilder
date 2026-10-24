# frozen_string_literal: true

# The modules render their prices and their hardpoints' component prices,
# which a price sync changes without touching the package, and the components,
# whose pictures change without touching it either.
json.cache! [
  "v7", I18n.locale, module_package, ::ScData::Source.current, ItemPrice.cache_key_for("Component", "ModelModule"), Component.touched_cache_key, Manufacturer.artwork_version
] do
  json.partial!("api/v1/model_module_packages/base", module_package:)
end
