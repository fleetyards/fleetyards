# frozen_string_literal: true

json.items do
  json.array! @notifications, partial: "admin/api/v1/notifications/notification", as: :notification
end
json.partial! "api/shared/meta", result: @notifications
