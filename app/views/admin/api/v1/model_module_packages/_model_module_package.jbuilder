# frozen_string_literal: true

json.cache! ["v1", model_module_package] do
  json.partial!("admin/api/v1/model_module_packages/base", model_module_package:)
end
