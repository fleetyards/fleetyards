# frozen_string_literal: true

json.id fleet_event_team.id
json.fleet_event_id fleet_event_team.fleet_event_id
json.title fleet_event_team.title
json.description fleet_event_team.description
json.position fleet_event_team.position

json.slots do
  json.array! fleet_event_team.fleet_event_slots,
    partial: "api/v1/fleet_event_slots/fleet_event_slot",
    as: :fleet_event_slot
end

json.ships do
  json.array! fleet_event_team.fleet_event_ships,
    partial: "api/v1/fleet_event_ships/fleet_event_ship",
    as: :fleet_event_ship
end
