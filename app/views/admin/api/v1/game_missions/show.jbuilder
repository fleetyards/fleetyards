# frozen_string_literal: true

json.partial! "admin/api/v1/game_missions/base", mission: @mission

json.description @mission.description
json.partial! "api/v1/game_missions/rewards", mission: @mission
