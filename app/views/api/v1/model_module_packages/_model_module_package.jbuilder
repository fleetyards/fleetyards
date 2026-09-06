# frozen_string_literal: true

json.cache! ["v1", module_package, Manufacturer.artwork_version] do
  json.partial!("api/v1/model_module_packages/base", module_package:)
end
