# frozen_string_literal: true

json.partial! "api/v1/fleet_events/base",
  fleet_event: @fleet_event,
  viewer_event_role: @viewer_event_role

json.teams do
  teams = @fleet_event.fleet_event_teams
    .includes(fleet_event_ships: [:model, fleet_event_slots: [:model_position]])
    .includes(fleet_event_slots: [:model_position])
  json.array! teams,
    partial: "api/v1/fleet_event_teams/fleet_event_team",
    as: :fleet_event_team
end

# Signups attached directly to the event (no slot yet) — admins assign these
# to slots later, and members see their own here.
json.unassigned_signups do
  json.array! @fleet_event.fleet_event_signups
    .where(fleet_event_slot_id: nil)
    .where.not(status: "withdrawn"),
    partial: "api/v1/fleet_event_signups/fleet_event_signup",
    as: :fleet_event_signup
end
