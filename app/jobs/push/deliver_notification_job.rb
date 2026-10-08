# frozen_string_literal: true

module Push
  # Fans one notification out to every browser its reader subscribed.
  #
  # One job per browser rather than a loop that raises on a rate limit: a retry
  # of the whole notification would push a second time to every browser that
  # already had it.
  class DeliverNotificationJob < ::ApplicationJob
    sidekiq_options retry: 2, queue: "notifications"

    # `seen_in_app` is whether a tab of the reader's was in use when the toast
    # went out. Then the push would only buzz the phone beside them. Decided
    # by whoever broadcast it, since only they know when that was.
    def perform(notification_id, seen_in_app = false)
      return if seen_in_app

      notification = Notification.find_by(id: notification_id)
      return if notification.blank?
      return unless self.class.deliverable?(notification)

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
  end
end
