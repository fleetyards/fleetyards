# frozen_string_literal: true

json.array! @notification_preferences, partial: "api/v1/notification_preferences/notification_preference", as: :notification_preference
