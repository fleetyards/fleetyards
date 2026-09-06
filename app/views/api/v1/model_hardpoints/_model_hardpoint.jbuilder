# frozen_string_literal: true

json.cache! ["v1", hardpoint, Manufacturer.artwork_version] do
  json.partial!("api/v1/model_hardpoints/base", hardpoint:)
end
