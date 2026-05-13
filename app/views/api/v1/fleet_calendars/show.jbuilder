# frozen_string_literal: true

json.items do
  json.array! @calendar_entries do |entry|
    event, occurrence_time = entry
    json.partial! "api/v1/fleet_events/base",
      fleet_event: event,
      occurrence_date: occurrence_time&.to_date,
      parent_event_slug: occurrence_time ? event.slug : nil
    if occurrence_time
      # Render the virtual occurrence at the occurrence's start time so
      # calendar clients place it on the right day.
      json.starts_at occurrence_time
      duration = event.ends_at ? (event.ends_at - event.starts_at) : 2.hours
      json.ends_at(occurrence_time + duration)
    end
  end
end
