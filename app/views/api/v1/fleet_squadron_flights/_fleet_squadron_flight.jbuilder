# frozen_string_literal: true

team = fleet_squadron_flight.team

json.id fleet_squadron_flight.id
json.name fleet_squadron_flight.name
json.short_description fleet_squadron_flight.short_description
json.description fleet_squadron_flight.description
json.position fleet_squadron_flight.position
json.team_id team.id

if fleet_squadron_flight.cover_image.attached?
  json.cover_image do
    json.partial! "api/v1/shared/file", record: fleet_squadron_flight, attr: :cover_image
  end
else
  json.cover_image nil
end

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
