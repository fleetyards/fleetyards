# frozen_string_literal: true

require "web_push"

module Push
  # Sends one notification to one browser.
  #
  # A gone or unknown endpoint is how a subscription normally ends -- the
  # reader revoked the permission, cleared site data or uninstalled the
  # browser -- so the row goes, quietly. A rate limit or an outage is worth a
  # retry. Anything else is this server's fault or the payload's, which a retry
  # does not change: it counts against the subscription, and one that keeps
  # failing goes.
  class DeliverToSubscriptionJob < ::ApplicationJob
    sidekiq_options retry: 3, queue: "notifications"

    MAX_FAILURES = 5

    # A day covers a device that is off overnight. Past that, most of what a
    # push says -- an event starting, a request waiting -- is stale.
    TTL = 1.day.to_i

    RETRYABLE = [
      WebPush::TooManyRequests,
      WebPush::PushServiceError,
      Net::OpenTimeout,
      Net::ReadTimeout,
      Errno::ECONNREFUSED,
      Errno::ECONNRESET,
      SocketError
    ].freeze

    # Only while the row is still the subscription this job was queued for: a
    # browser that moved accounts, or renewed its keys, since must not pay for
    # sends to what it was before.
    sidekiq_retries_exhausted do |job, _exception|
      notification_id, subscription_id, key_digest = job["args"]
      subscription = PushSubscription.find_by(id: subscription_id)
      owner_id = Notification.where(id: notification_id).pick(:user_id)
      next unless subscription && subscription.user_id == owner_id
      next if key_digest && subscription.key_digest != key_digest

      DeliverToSubscriptionJob.record_failure(subscription)
    end

    def perform(notification_id, subscription_id, _key_digest = nil)
      notification = Notification.find_by(id: notification_id)
      subscription = PushSubscription.find_by(id: subscription_id)
      return if notification.blank? || subscription.blank?
      return unless subscription.user_id == notification.user_id
      # Again at send time: the queue can be minutes behind, and a reader who
      # switched push off meanwhile must not get it anyway.
      return unless DeliverNotificationJob.deliverable?(notification)

      send_push(notification, subscription)
      subscription.update_columns(last_delivered_at: Time.current, failure_count: 0, last_failed_at: nil)
    rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
      self.class.as_sent(subscription, &:destroy)
    rescue *RETRYABLE
      raise
    rescue WebPush::ResponseError => e
      Rails.logger.warn("[Push::DeliverToSubscriptionJob] subscription=#{subscription.id} not delivered: #{e.class}")
      self.class.as_sent(subscription) { |row| self.class.record_failure(row) }
    end

    # An answer is about the keys and the owner the push went out with. If the
    # browser renewed or moved accounts while it was in flight, the row is a
    # different subscription now and the answer says nothing about it.
    def self.as_sent(sent)
      PushSubscription.transaction do
        row = PushSubscription.lock.find_by(id: sent.id)
        next unless row && row.user_id == sent.user_id
        next unless row.p256dh_key == sent.p256dh_key && row.auth_key == sent.auth_key

        yield row
      end
    end

    # In SQL, so two sends failing at once both count.
    def self.record_failure(subscription)
      failures = PushSubscription.where(id: subscription.id)
        .update_all(["failure_count = failure_count + 1, last_failed_at = ?", Time.current])
      return if failures.zero?

      PushSubscription.where(id: subscription.id, failure_count: MAX_FAILURES..).delete_all
    end

    private def send_push(notification, subscription)
      WebPush.payload_send(
        message: Payload.new(notification).to_json,
        endpoint: subscription.endpoint,
        p256dh: subscription.p256dh_key,
        auth: subscription.auth_key,
        vapid: {subject: Vapid.subject, public_key: Vapid.public_key, private_key: Vapid.private_key},
        ttl: TTL,
        urgency: "normal",
        open_timeout: 5,
        read_timeout: 10
      )
    end
  end
end
