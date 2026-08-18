# frozen_string_literal: true

json.id @occurrence_state.id
json.fleet_event_id @occurrence_state.fleet_event_id
json.occurrence_date @occurrence_state.occurrence_date
json.status @occurrence_state.status
json.locked_at @occurrence_state.locked_at
json.starting_soon_notified_at @occurrence_state.starting_soon_notified_at
json.cancelled_at @occurrence_state.cancelled_at
json.cancelled_reason @occurrence_state.cancelled_reason
json.discord_event_id @occurrence_state.discord_event_id
json.discord_synced_at @occurrence_state.discord_synced_at
json.title @occurrence_state.title
json.description @occurrence_state.description
json.briefing @occurrence_state.briefing
json.location @occurrence_state.location
json.meetup_location @occurrence_state.meetup_location
json.scenario @occurrence_state.scenario
json.cover_image_preset @occurrence_state.cover_image_preset
