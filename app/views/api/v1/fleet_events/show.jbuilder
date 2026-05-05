# frozen_string_literal: true

json.partial! "api/v1/fleet_events/base", fleet_event: @fleet_event

json.teams do
  teams = @fleet_event.fleet_event_teams
    .includes(fleet_event_ships: [:model, fleet_event_slots: [:model_position]])
    .includes(fleet_event_slots: [:model_position])
  json.array! teams,
    partial: "api/v1/fleet_event_teams/fleet_event_team",
    as: :fleet_event_team
end
