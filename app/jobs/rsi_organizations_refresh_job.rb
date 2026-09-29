# frozen_string_literal: true

# Re-reads the organisations page of everybody with a proved handle, so a member
# who left the RSI org is noticed without anyone asking. Runs hourly and takes a
# 24th of them each time, so the requests to RSI spread over the day.
class RsiOrganizationsRefreshJob < ::ApplicationJob
  sidekiq_options queue: "loaders"

  PAUSE_KEY = "rsi_organizations_refresh:paused"

  # Short of a day, so an hour's drift between runs does not skip anyone.
  RECHECK_AFTER = 20.hours

  # Everybody whose handle is proved, not only members of verified fleets: a
  # list kept current lets a fleet that verifies its SID, or a member who
  # joins, be answered from it without a request of their own.
  def self.eligible
    User.where(rsi_handle_verified: true).where.not(rsi_handle: nil)
  end

  def perform
    return if Rails.cache.read(PAUSE_KEY)

    eligible = self.class.eligible
    batch_size = (eligible.count / 24.0).ceil
    return if batch_size.zero?

    due = eligible
      .where("users.rsi_organizations_attempted_at IS NULL OR users.rsi_organizations_attempted_at < ?", RECHECK_AFTER.ago)
      .order(Arel.sql("users.rsi_organizations_attempted_at ASC NULLS FIRST"))
      .limit(batch_size)

    due.each do |user|
      next unless UserRsiOrganizations.new(user).run == :blocked

      # RSI refused us: asking again within the day only prolongs it.
      Rails.cache.write(PAUSE_KEY, true, expires_at: Time.current.end_of_day)
      break
    rescue => e
      Appsignal.report_error(e)
    end
  end
end
