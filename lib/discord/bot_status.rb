# frozen_string_literal: true

module Discord
  # What bin/discord-bot reports about its Gateway connection, so the web
  # side can tell a fleet whether role changes reach it as they happen --
  # from the bot itself, not from an env var the web process may not share.
  module BotStatus
    KEY = "discord-bot:status"

    # Discord heartbeats about every 40 seconds; missing several means the
    # bot is gone.
    STALE_AFTER = 5.minutes

    def self.record!(members_intent:)
      Rails.cache.write(KEY, {"members_intent" => members_intent, "at" => Time.current.iso8601}, expires_in: STALE_AFTER)
    end

    def self.clear!
      Rails.cache.delete(KEY)
    end

    # nil when no bot reported recently.
    def self.current
      Rails.cache.read(KEY)
    end
  end
end
