# frozen_string_literal: true

json.cache! ["v1", model_module, ::ScData::Source.current, Manufacturer.artwork_version] do
  json.partial!("api/v1/model_modules/base", model_module:)
end
