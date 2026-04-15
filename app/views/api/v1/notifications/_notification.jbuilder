# frozen_string_literal: true

json.cache! ["v1", notification] do
  json.partial!("api/v1/notifications/base", notification:)
end
