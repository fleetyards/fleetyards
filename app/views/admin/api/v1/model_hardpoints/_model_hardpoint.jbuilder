# frozen_string_literal: true

json.cache! ["v1", model_hardpoint, Manufacturer.artwork_version] do
  json.partial!("admin/api/v1/model_hardpoints/base", model_hardpoint:)
end
