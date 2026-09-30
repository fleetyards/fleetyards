# frozen_string_literal: true

# The embedded models are keyed too, by their newest change: a measurement
# changes a model without touching the module.
json.cache! ["v3", model_module, model_module.models.maximum(:updated_at), Manufacturer.artwork_version] do
  json.partial!("admin/api/v1/model_modules/base", model_module:)
end
