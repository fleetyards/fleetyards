# frozen_string_literal: true

require "discord/direct_message"
require "discord/locale"

module Discord
  # Sends one notification as a Discord DM.
  #
  # Out of band because Notification.notify! runs inside whatever request or job
  # produced the notification, and two Discord round trips -- open the channel,
  # post the message -- have no business holding that up.
  class DeliverNotificationJob < ::ApplicationJob
    sidekiq_options retry: 2, queue: "notifications"

    def perform(notification_id)
      notification = Notification.find_by(id: notification_id)
      return if notification.blank?

      # The reader's own language, not the sender's: this arrives in their DMs.
      # Through Locale.resolve because the column is free text and an
      # unavailable locale raises rather than falling back.
      I18n.with_locale(Locale.resolve(notification.user&.locale)) do
        DirectMessage.new(notification).run
      end
    end
  end
end
