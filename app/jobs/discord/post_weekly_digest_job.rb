# frozen_string_literal: true

require "discord/weekly_digest"

module Discord
  class PostWeeklyDigestJob < ::ApplicationJob
    sidekiq_options retry: 2, queue: "notifications"

    # The dispatcher marks the week sent before this runs, so a digest that
    # never went out has to give the mark back -- otherwise the next tick
    # within the grace period would skip it as already done.
    sidekiq_retries_exhausted do |job, _exception|
      fleet_id, claimed_at = job["args"]
      WeeklyDigestDispatchJob.release(fleet_id, Time.iso8601(claimed_at)) if claimed_at
    end

    def perform(fleet_id, claimed_at = nil)
      fleet = Fleet.kept.find_by(id: fleet_id)
      return if fleet.blank?

      setting = fleet.fleet_notification_setting
      # Switched off between being queued and being run.
      return unless setting&.digest_enabled?

      # Rescheduled meanwhile: the old slot is abandoned, and its claim is
      # given back so the new one is not held off by it.
      if claimed_at.present?
        claimed_at = Time.iso8601(claimed_at)

        unless setting.digest_claim_current?(claimed_at)
          WeeklyDigestDispatchJob.release(fleet_id, claimed_at)
          return
        end
      end

      WeeklyDigest.new(fleet, claimed_at: claimed_at).run
    end
  end
end
