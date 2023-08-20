# frozen_string_literal: true

json.cache! ["v1", model_module] do
  json.partial!("api/v1/model_modules/base", model_module:)
end
