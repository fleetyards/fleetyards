# frozen_string_literal: true

json.items do
  json.array! @calendar_entries do |entry|
    json.partial! "api/v1/fleet_calendars/entry", entry:, viewer_signups: @viewer_signups
  end
end
