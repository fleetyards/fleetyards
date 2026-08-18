# frozen_string_literal: true

json.id mission_team.id
json.mission_id mission_team.mission_id
json.title mission_team.title
json.description mission_team.description
json.position mission_team.position

json.slots do
  json.array! mission_team.mission_slots,
    partial: "api/v1/mission_slots/mission_slot",
    as: :mission_slot
end

json.ships do
  json.array! mission_team.mission_ships,
    partial: "api/v1/mission_ships/mission_ship",
    as: :mission_ship
end
