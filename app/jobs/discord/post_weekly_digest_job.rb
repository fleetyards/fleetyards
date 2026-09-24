# frozen_string_literal: true

require "discord/weekly_digest"

module Discord
  class PostWeeklyDigestJob < ::ApplicationJob
    sidekiq_options retry: 2, queue: "notifications"

    # The dispatcher marks the week sent before this runs, so a digest that
    # never went out has to give the mark back -- otherwise the next tick
    # within the grace period would skip it as already done.
    sidekiq_retries_exhausted do |job, _exception|
      WeeklyDigestDispatchJob.release(job["args"].first)
    end

    def perform(fleet_id)
      fleet = Fleet.kept.find_by(id: fleet_id)
      return if fleet.blank?

      # Switched off between being queued and being run.
      return unless fleet.fleet_notification_setting&.digest_enabled?

      WeeklyDigest.new(fleet).run
    end
  end
end
