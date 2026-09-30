# frozen_string_literal: true

# The embedded model is keyed too: a measurement changes it without touching
# the paint.
json.cache! ["v3", model_paint, model_paint.model, Manufacturer.artwork_version] do
  json.partial!("admin/api/v1/model_paints/base", model_paint:)
end
