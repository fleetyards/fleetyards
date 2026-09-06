# frozen_string_literal: true

json.cache! ["v1", hardpoint, hardpoint.component, Manufacturer.artwork_version] do
  json.partial!("api/v1/hardpoints/base", hardpoint:)
end
