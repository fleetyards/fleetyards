# frozen_string_literal: true

json.id fleet_event.id
json.fleet_id fleet_event.fleet_id
json.mission_id fleet_event.mission_id
json.title fleet_event.title
json.slug fleet_event.slug
json.description fleet_event.description
json.briefing fleet_event.briefing
json.status fleet_event.status
json.starts_at fleet_event.starts_at
json.ends_at fleet_event.ends_at
json.timezone fleet_event.timezone
json.location fleet_event.location
json.meetup_location fleet_event.meetup_location
json.visibility fleet_event.visibility
json.category fleet_event.category
json.scenario fleet_event.scenario
json.cover_image_preset fleet_event.cover_image_preset
json.max_attendees fleet_event.max_attendees
json.auto_lock_enabled fleet_event.auto_lock_enabled
json.auto_lock_minutes_before fleet_event.auto_lock_minutes_before
json.cancelled_reason fleet_event.cancelled_reason
json.archived fleet_event.archived?
json.archived_at fleet_event.archived_at
json.external_uid fleet_event.external_uid

if fleet_event.cover_image.attached?
  json.cover_image do
    json.partial! "api/v1/shared/file", record: fleet_event, attr: :cover_image
  end
else
  json.cover_image nil
end

if fleet_event.created_by.present?
  json.created_by do
    json.id fleet_event.created_by.id
    json.username fleet_event.created_by.username
  end
else
  json.created_by nil
end

json.signups_count fleet_event.signups_count
json.team_count fleet_event.fleet_event_teams.size

json.partial! "api/shared/dates", record: fleet_event
