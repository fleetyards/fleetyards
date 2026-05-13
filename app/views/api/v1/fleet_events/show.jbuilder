# frozen_string_literal: true

json.partial! "api/v1/fleet_events/base",
  fleet_event: @fleet_event,
  viewer_event_role: @viewer_event_role,
  occurrence_date: @occurrence_date,
  parent_event_slug: @occurrence_date ? @fleet_event.slug : nil

# Per-occurrence override of fields when the request is scoped to a
# specific date (?occurrence=YYYY-MM-DD). The starts_at/ends_at are
# shifted to that day; titles, descriptions, location etc. prefer the
# overlay row's values over the event defaults.
if @occurrence_date
  occurrence_start = @fleet_event.starts_at.in_time_zone(@fleet_event.timezone || "UTC").change(
    year: @occurrence_date.year,
    month: @occurrence_date.month,
    day: @occurrence_date.day
  )
  duration = @fleet_event.ends_at ? (@fleet_event.ends_at - @fleet_event.starts_at) : 2.hours

  json.starts_at occurrence_start
  json.ends_at(occurrence_start + duration)

  if @occurrence_state
    json.title @occurrence_state.title.presence || @fleet_event.title
    json.description @occurrence_state.description.presence || @fleet_event.description
    json.briefing @occurrence_state.briefing.presence || @fleet_event.briefing
    json.location @occurrence_state.location.presence || @fleet_event.location
    json.meetup_location @occurrence_state.meetup_location.presence || @fleet_event.meetup_location
    json.scenario @occurrence_state.scenario.presence || @fleet_event.scenario
    json.cover_image_preset @occurrence_state.cover_image_preset.presence || @fleet_event.cover_image_preset
    json.status @occurrence_state.status.presence || @fleet_event.status
    json.discord_event_id @occurrence_state.discord_event_id
    json.discord_synced_at @occurrence_state.discord_synced_at
  end
end

json.teams do
  teams = @fleet_event.fleet_event_teams
    .includes(fleet_event_ships: [:model, fleet_event_slots: [:model_position]])
    .includes(fleet_event_slots: [:model_position])
  json.array! teams,
    partial: "api/v1/fleet_event_teams/fleet_event_team",
    as: :fleet_event_team,
    locals: {occurrence_date: @occurrence_date}
end

# Signups attached directly to the event (no slot yet) — admins assign these
# to slots later, and members see their own here. For recurring events the
# list is scoped to the requested occurrence so members see signups for the
# specific Thursday they're looking at.
unassigned_scope = @fleet_event.fleet_event_signups
  .where(fleet_event_slot_id: nil)
  .where.not(status: "withdrawn")
unassigned_scope = unassigned_scope.where(occurrence_date: @occurrence_date) if @occurrence_date

json.unassigned_signups do
  json.array! unassigned_scope,
    partial: "api/v1/fleet_event_signups/fleet_event_signup",
    as: :fleet_event_signup
end
