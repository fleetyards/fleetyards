# frozen_string_literal: true

team = fleet_squadron_flight.team

json.id fleet_squadron_flight.id
json.name fleet_squadron_flight.name
json.description fleet_squadron_flight.description
json.position fleet_squadron_flight.position
json.team_id team.id

json.slots do
  json.array! team.mission_slots,
    partial: "api/v1/mission_slots/mission_slot",
    as: :mission_slot
end

json.ships do
  json.array! team.mission_ships,
    partial: "api/v1/mission_ships/mission_ship",
    as: :mission_ship
end

json.partial! "api/shared/dates", record: fleet_squadron_flight
