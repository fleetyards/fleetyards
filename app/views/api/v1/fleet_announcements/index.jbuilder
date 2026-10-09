# frozen_string_literal: true

json.items do
  json.array! @fleet_announcements, partial: "api/v1/fleet_announcements/fleet_announcement", as: :fleet_announcement
end
