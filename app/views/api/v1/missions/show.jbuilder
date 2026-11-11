# frozen_string_literal: true

json.partial! "api/v1/missions/base", mission: @mission

json.teams do
  slots = {mission_slots: {mission_slot_candidates: SlotCandidate::RENDER_PRELOADS}}
  json.array! @mission.mission_teams.includes(slots, mission_ships: [:model, slots], fleet_squadron: {icon_attachment: :blob}),
    partial: "api/v1/mission_teams/mission_team",
    as: :mission_team
end
