# frozen_string_literal: true

json.cache! ["v1", hardpoint] do
  json.partial!("api/v1/hardpoints/base", hardpoint:)
end
