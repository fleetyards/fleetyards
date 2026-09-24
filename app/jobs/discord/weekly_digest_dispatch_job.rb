# frozen_string_literal: true

module Discord
  # Finds the fleets whose weekly digest has come due and hands each to its own
  # job, so one slow guild does not hold up every other fleet's digest.
  class WeeklyDigestDispatchJob < ::ApplicationJob
    sidekiq_options retry: false, queue: "notifications"

    def perform
      now = Time.current

      FleetNotificationSetting.where.not(discord_digest_weekday: nil).includes(:fleet).find_each do |setting|
        next unless setting.digest_due?(now)
        next unless claim(setting, setting.digest_slot(now))

        PostWeeklyDigestJob.perform_async(setting.fleet_id)
      end
    end

    # Stamped before the post is queued, and only by whichever run gets there
    # first: two overlapping ticks would otherwise both find it due.
    private def claim(setting, slot)
      FleetNotificationSetting
        .where(id: setting.id)
        .where("discord_digest_sent_at IS NULL OR discord_digest_sent_at < ?", slot)
        .update_all(discord_digest_sent_at: Time.current) == 1
    end
  end
end
