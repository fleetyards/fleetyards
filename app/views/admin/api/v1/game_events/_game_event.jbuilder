# frozen_string_literal: true

json.cache! ["v1", game_event] do
  json.partial!("admin/api/v1/game_events/base", game_event:)
end
