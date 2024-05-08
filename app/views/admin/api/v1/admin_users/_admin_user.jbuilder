# frozen_string_literal: true

json.cache! ["v1", admin_user] do
  json.partial!("admin/api/v1/admin_users/base", admin_user:)
end
