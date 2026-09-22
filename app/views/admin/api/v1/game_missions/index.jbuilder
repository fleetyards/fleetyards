# frozen_string_literal: true

json.items do
  json.array! @missions, partial: "admin/api/v1/game_missions/game_mission", as: :mission
end
json.partial! "api/shared/meta", result: @missions
