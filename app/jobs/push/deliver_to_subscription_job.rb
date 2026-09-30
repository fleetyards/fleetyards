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

    sidekiq_retries_exhausted do |job, _exception|
      subscription = PushSubscription.find_by(id: job["args"].last)
      subscription && DeliverToSubscriptionJob.record_failure(subscription)
    end

    def perform(notification_id, subscription_id)
      notification = Notification.find_by(id: notification_id)
      subscription = PushSubscription.find_by(id: subscription_id)
      return if notification.blank? || subscription.blank?
      return unless subscription.user_id == notification.user_id
      return unless Vapid.configured?

      send_push(notification, subscription)
      subscription.update_columns(last_delivered_at: Time.current, failure_count: 0, last_failed_at: nil)
    rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
      subscription.destroy
    rescue *RETRYABLE
      raise
    rescue WebPush::ResponseError => e
      Rails.logger.warn("[Push::DeliverToSubscriptionJob] subscription=#{subscription.id} not delivered: #{e.class}")
      self.class.record_failure(subscription)
    end

    def self.record_failure(subscription)
      if subscription.failure_count + 1 >= MAX_FAILURES
        subscription.destroy
      else
        subscription.update_columns(failure_count: subscription.failure_count + 1, last_failed_at: Time.current)
      end
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
