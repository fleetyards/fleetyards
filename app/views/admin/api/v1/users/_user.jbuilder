# frozen_string_literal: true

json.cache! ["v1", user] do
  json.partial!("admin/api/v1/users/base", user:)
end
