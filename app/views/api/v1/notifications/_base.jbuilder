# frozen_string_literal: true

json.id notification.id
json.notification_type notification.notification_type
json.title notification.title
json.body notification.body
json.link notification.link
json.icon notification.icon
json.read notification.read?
json.read_at notification.read_at&.utc&.iso8601
json.archived notification.archived?
json.archived_at notification.archived_at&.utc&.iso8601
json.deletes_at notification.deletes_at&.utc&.iso8601
json.expires_at notification.expires_at.utc.iso8601

# A reference to the record the notification is about, so the reader can load
# it and see what state it is in now. Nothing about that state is written here:
# this partial is fragment-cached, and a status cached alongside the
# notification would still read as open long after the invite was answered.
reference = NotificationRecordReference.for(notification)

if reference.present?
  json.record do
    reference.each { |key, value| json.set!(key, value) }
  end
end

json.partial! "api/shared/dates", record: notification
