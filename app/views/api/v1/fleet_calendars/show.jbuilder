# frozen_string_literal: true

json.items do
  json.array! @calendar_entries do |entry|
    event, occurrence_time = entry
    state =
      if occurrence_time
        event.occurrence_state_for(occurrence_time.to_date)
      end

    json.partial! "api/v1/fleet_events/base",
      fleet_event: event,
      occurrence_date: occurrence_time&.to_date,
      parent_event_slug: occurrence_time ? event.slug : nil

    viewer_signup = @viewer_signups[[event.id, occurrence_time&.to_date]]
    if viewer_signup
      json.viewer_signup do
        json.id viewer_signup.id
        json.status viewer_signup.status
        json.occurrence_date viewer_signup.occurrence_date
      end
    else
      json.viewer_signup nil
    end

    if occurrence_time
      # Render the virtual occurrence at the occurrence's start time so
      # calendar clients place it on the right day.
      json.starts_at occurrence_time
      duration = event.ends_at ? (event.ends_at - event.starts_at) : 2.hours
      json.ends_at(occurrence_time + duration)
    end

    if state
      json.title state.title.presence || event.title
      json.description state.description.presence || event.description
      json.location state.location.presence || event.location
      json.meetup_location state.meetup_location.presence || event.meetup_location
      json.partial! "api/v1/locations/linked", key: :linked_location,
        location: state.location.present? ? state.linked_location : event.linked_location
      json.partial! "api/v1/locations/linked", key: :linked_meetup_location,
        location: state.meetup_location.present? ? state.linked_meetup_location : event.linked_meetup_location
      json.scenario state.scenario.presence || event.scenario
      json.cover_image_preset state.cover_image_preset.presence || event.cover_image_preset
      json.status state.status.presence || event.status
    end
  end
end
