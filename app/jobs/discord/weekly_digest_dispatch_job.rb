# frozen_string_literal: true

module Discord
  # Finds the fleets whose weekly digest has come due and hands each to its own
  # job, so one slow guild does not hold up every other fleet's digest.
  class WeeklyDigestDispatchJob < ::ApplicationJob
    sidekiq_options retry: false, queue: "notifications"

    def perform
      now = Time.current

      FleetNotificationSetting
        .where.not(discord_digest_weekday: nil)
        .joins(:fleet).merge(Fleet.kept)
        .includes(:fleet)
        .find_each do |setting|
          next unless setting.digest_due?(now)
          next unless claim(setting, setting.digest_slot(now))

          begin
            PostWeeklyDigestJob.perform_async(setting.fleet_id)
          rescue
            self.class.release(setting.fleet_id)
            raise
          end
        end
    end

    # Gives a claimed week back, so a digest that could not be sent is tried
    # again by the next tick still inside its grace period.
    def self.release(fleet_id)
      FleetNotificationSetting.where(fleet_id: fleet_id).update_all(discord_digest_sent_at: nil)
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
