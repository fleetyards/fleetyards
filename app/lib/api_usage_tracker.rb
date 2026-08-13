# frozen_string_literal: true

# Counts API requests per OAuth application in Redis so third-party clients show
# up in the metrics without a database write on the request path. Counters are
# aggregate only — no per-user rows — and get rolled into `Rollup` by MetricsJob.
class ApiUsageTracker
  NAMESPACE = "api-usage"
  ROLLUP_NAME = "API Usage"
  RETENTION = 8.days

  class << self
    def track(application_id, time: Time.current)
      return if application_id.blank?

      store.increment(key(application_id, time), 1, expires_in: RETENTION)
    end

    def count(application_id, time)
      store.read(key(application_id, time), raw: true).to_i
    end

    def reset(application_id, time)
      store.delete(key(application_id, time))
    end

    # Counters ready to be rolled up, as `[day, application_id, count]`. Read from
    # Redis rather than from the application table so counters of an application
    # that was deleted since its requests are still found.
    def pending_counters(now: Time.current)
      days = pending_days(now:).index_by { |day| day.utc.to_date.iso8601 }

      tracked_keys.filter_map do |key|
        date, application_id = key.split(":", 2)
        day = days[date]
        next if day.blank? || application_id.blank?

        requests = count(application_id, day)
        next if requests.zero?

        [day, application_id, requests]
      end
    end

    # Days that may still hold counters, newest first, excluding today so a day is
    # only rolled up once it can no longer receive requests.
    def pending_days(now: Time.current)
      today = now.utc.to_date
      (1..RETENTION.in_days.to_i).map { |offset| (today - offset).in_time_zone("UTC") }
    end

    private def tracked_keys
      prefix = "#{namespace}:"

      store.redis.then do |redis|
        redis.scan_each(match: "#{prefix}*").map { |key| key.delete_prefix(prefix) }
      end
    end

    private def key(application_id, time)
      "#{time.utc.to_date.iso8601}:#{application_id}"
    end

    # Tests share the Redis instance with the local app and run in parallel
    # processes, so every worker scans its own keys only.
    private def namespace
      return NAMESPACE unless Rails.env.test?

      "#{NAMESPACE}-test-#{Process.pid}"
    end

    private def store
      @store ||= ActiveSupport::Cache::RedisCacheStore.new(
        url: Rails.configuration.redis.url,
        db: 1,
        namespace:
      )
    end
  end
end
