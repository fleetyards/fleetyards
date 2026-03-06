# frozen_string_literal: true

json.cache! ["admin-v1", hardpoint] do
  json.partial!("admin/api/v1/hardpoints/base", hardpoint:)
end
