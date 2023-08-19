# frozen_string_literal: true

json.cache! ["v1", module_package] do
  json.partial!("api/v1/model_module_packages/base", module_package:)
end
