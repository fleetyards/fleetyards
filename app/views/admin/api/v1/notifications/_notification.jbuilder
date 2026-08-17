# frozen_string_literal: true

json.cache! ["admin-v1", notification] do
  json.partial!("admin/api/v1/notifications/base", notification:)
end
