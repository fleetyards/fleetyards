# frozen_string_literal: true

module Maintenance
  class BackfillNotificationPreferencesTask < MaintenanceTasks::Task
    def collection
      User.all
    end

    def count
      collection.count
    end

    def process(user)
      Notification.notification_types.each_key do |type|
        defaults = NotificationPreference.defaults_for(type)

        user.notification_preferences.find_or_create_by!(notification_type: type) do |pref|
          if type == "model_on_sale"
            pref.app = user.sale_notify?
            pref.mail = user.sale_notify?
            pref.push = false
          else
            pref.app = defaults[:app]
            pref.mail = defaults[:mail]
            pref.push = defaults[:push]
          end
        end
      end
    end
  end
end
