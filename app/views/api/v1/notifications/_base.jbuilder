# frozen_string_literal: true

json.id notification.id
json.notification_type notification.notification_type
json.title notification.title
json.body notification.body
json.link notification.link
json.icon notification.icon
json.read notification.read?
json.read_at notification.read_at&.utc&.iso8601
json.expires_at notification.expires_at.utc.iso8601
json.partial! "api/shared/dates", record: notification
