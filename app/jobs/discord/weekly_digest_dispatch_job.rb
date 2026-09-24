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

          claimed_at = claim(setting, setting.digest_slot(now))
          next if claimed_at.nil?

          begin
            PostWeeklyDigestJob.perform_async(setting.fleet_id, claimed_at.iso8601(6))
          rescue
            self.class.release(setting.fleet_id, claimed_at)
            raise
          end
        end
    end

    # Gives a claimed week back, so a digest that could not be sent is tried
    # again by the next tick still inside its grace period. Only the claim it
    # made: a job that failed slowly must not reopen a later week somebody
    # else has claimed since.
    def self.release(fleet_id, claimed_at)
      FleetNotificationSetting
        .where(fleet_id: fleet_id, discord_digest_sent_at: claimed_at)
        .update_all(discord_digest_sent_at: nil)
    end

    # Stamped before the post is queued, and only by whichever run gets there
    # first: two overlapping ticks would otherwise both find it due. The stamp
    # is the claim's identity, so it is kept at the precision the column
    # stores.
    private def claim(setting, slot)
      claimed_at = Time.current.floor(6)

      won = FleetNotificationSetting
        .where(id: setting.id)
        .where("discord_digest_sent_at IS NULL OR discord_digest_sent_at < ?", slot)
        .update_all(discord_digest_sent_at: claimed_at) == 1

      won ? claimed_at : nil
    end
  end
end
