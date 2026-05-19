# frozen_string_literal: true

json.cache! ["v1", "admin_user_fleet", membership] do
  json.partial!("admin/api/v1/user_fleets/base", membership:)
end
