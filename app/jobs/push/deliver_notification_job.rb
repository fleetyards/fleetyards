# frozen_string_literal: true

module Push
  # Fans one notification out to every browser its reader subscribed.
  #
  # One job per browser rather than a loop that raises on a rate limit: a retry
  # of the whole notification would push a second time to every browser that
  # already had it.
  class DeliverNotificationJob < ::ApplicationJob
    sidekiq_options retry: 2, queue: "notifications"

    def perform(notification_id)
      notification = Notification.find_by(id: notification_id)
      return if notification.blank?
      return unless self.class.deliverable?(notification)
      return if self.class.seen_in_app?(notification)

      subscriptions = notification.user.push_subscriptions.to_a
      return if subscriptions.empty?

      DeliverToSubscriptionJob.perform_bulk(
        subscriptions.map { |subscription| [notification.id, subscription.id, subscription.key_digest] }
      )
    end

    # Checked here rather than when the reader's switch was flipped: the flag,
    # the keys and the type's channels can all change after that.
    def self.deliverable?(notification)
      Vapid.configured? &&
        Notification.channels_for(notification.notification_type).include?(:push) &&
        Flipper.enabled?(:push_notifications, notification.user) &&
        NotificationPreference.for(user: notification.user, type: notification.notification_type).push?
    end

    # A reader with the app in front of them on any device already got this as
    # a toast, so the push would only buzz the phone beside them. Only when the
    # in-app channel is on for the type -- otherwise the push is all they get.
    #
    # Decided once, here, not again at send time: a retry or a backed-up queue
    # would otherwise drop a push that was due while the reader was away.
    def self.seen_in_app?(notification)
      NotificationPreference.for(user: notification.user, type: notification.notification_type).app? &&
        UserPresence.active?(notification.user_id)
    end
  end
end
