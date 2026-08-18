# frozen_string_literal: true

json.partial! "api/v1/missions/base", mission: @mission

json.teams do
  json.array! @mission.mission_teams.includes(:mission_slots, mission_ships: [:model, :mission_slots]),
    partial: "api/v1/mission_teams/mission_team",
    as: :mission_team
end
