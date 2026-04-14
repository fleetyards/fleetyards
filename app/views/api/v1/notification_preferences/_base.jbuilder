# frozen_string_literal: true

json.notification_type notification_preference.notification_type
json.app notification_preference.app?
json.mail notification_preference.mail?
json.push notification_preference.push?
json.mail_available NotificationPreference.mail_available?(notification_preference.notification_type)
