# frozen_string_literal: true

require "discord/scheduled_event_rsvp_sync"

module Discord
  # Polls one Discord scheduled event's subscriber list and mirrors it into
  # Fleetyards signups.
  class PollEventRsvpsJob < ::ApplicationJob
    sidekiq_options retry: 3, queue: "notifications"

    # Positional on purpose: Sidekiq replays arguments positionally, so a
    # keyword here raises ArgumentError for every job the dispatcher enqueues.
    def perform(discord_event_id, guild_id)
      sync = ScheduledEventRsvpSync.new(guild_id: guild_id, discord_event_id: discord_event_id)
      return unless sync.runnable?

      result = sync.run!
      return if result.nil?

      return if result.added.zero? && result.removed.zero?

      Rails.logger.info("[Discord::PollEventRsvpsJob] event=#{discord_event_id} #{result}")
    rescue ApiClient::Error => e
      Rails.logger.error("[Discord::PollEventRsvpsJob] event=#{discord_event_id} failed: #{e.message}")
      raise if e.status == 429 || e.status >= 500
    end
  end
end
