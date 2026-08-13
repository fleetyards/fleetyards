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

    # Days that may still hold counters, newest first, excluding today so a day is
    # only rolled up once it can no longer receive requests.
    def pending_days(now: Time.current)
      today = now.utc.to_date
      (1..RETENTION.in_days.to_i).map { |offset| (today - offset).in_time_zone("UTC") }
    end

    private def key(application_id, time)
      "#{time.utc.to_date.iso8601}:#{application_id}"
    end

    private def store
      @store ||=
        if Rails.env.test?
          ActiveSupport::Cache::MemoryStore.new
        else
          ActiveSupport::Cache::RedisCacheStore.new(
            url: Rails.configuration.redis.url,
            db: 1,
            namespace: NAMESPACE
          )
        end
    end
  end
end
