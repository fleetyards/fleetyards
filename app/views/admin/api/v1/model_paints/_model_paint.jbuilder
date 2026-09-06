# frozen_string_literal: true

json.cache! ["v1", model_paint, Manufacturer.artwork_version] do
  json.partial!("admin/api/v1/model_paints/base", model_paint:)
end
