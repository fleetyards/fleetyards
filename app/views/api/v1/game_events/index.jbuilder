# frozen_string_literal: true

json.items do
  json.array! @game_events, partial: "api/v1/game_events/game_event", as: :game_event
end
json.partial! "api/shared/meta", result: @game_events
