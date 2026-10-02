# frozen_string_literal: true

# Re-reads the RSI org of every verified fleet, so the directory follows what
# the org's officers change on RSI. Runs hourly and takes a 24th of them each
# time, so the requests to RSI spread over the day.
class FleetRsiRefreshJob < ::ApplicationJob
  sidekiq_options queue: "loaders"

  PAUSE_KEY = "fleet_rsi_refresh:paused"

  # Short of a day, so an hour's drift between runs does not skip anyone.
  RECHECK_AFTER = 20.hours

  def perform
    return if Rails.cache.read(PAUSE_KEY)

    eligible = Fleet.kept.rsi_verified
    batch_size = (eligible.count / 24.0).ceil
    return if batch_size.zero?

    due = eligible
      .where("fleets.rsi_sync_attempted_at IS NULL OR fleets.rsi_sync_attempted_at < ?", RECHECK_AFTER.ago)
      .order(Arel.sql("fleets.rsi_sync_attempted_at ASC NULLS FIRST"))
      .limit(batch_size)

    due.each do |fleet|
      next unless FleetRsiSync.new(fleet).run == :blocked

      # RSI refused us: asking again within the day only prolongs it.
      Rails.cache.write(PAUSE_KEY, true, expires_at: Time.current.end_of_day)
      break
    rescue => e
      Appsignal.report_error(e)
    end
  end
end
