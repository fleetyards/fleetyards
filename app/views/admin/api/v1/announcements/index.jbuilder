# frozen_string_literal: true

json.items do
  json.array! @announcements, partial: "admin/api/v1/announcements/announcement", as: :announcement
end
json.partial! "api/shared/meta", result: @announcements
