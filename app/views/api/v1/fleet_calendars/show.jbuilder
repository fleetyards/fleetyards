# frozen_string_literal: true

json.items do
  json.array! @events,
    partial: "api/v1/fleet_events/fleet_event",
    as: :fleet_event
end
