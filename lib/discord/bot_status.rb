# frozen_string_literal: true

module Discord
  # What bin/discord-bot reports about its Gateway connection, so the web
  # side can tell a fleet whether role changes reach it as they happen --
  # from the bot itself, not from an env var the web process may not share.
  #
  # Refreshed on every heartbeat and left to expire rather than cleared on
  # disconnect: discordrb raises a disconnect for every dropped socket,
  # including one it resumes without a new READY, and runs each handler on
  # its own thread, so a heartbeat in flight could rewrite a cleared report.
  module BotStatus
    KEY = "discord-bot:status"

    # Discord heartbeats about every 40 seconds; three missed means the bot
    # is gone.
    STALE_AFTER = 2.minutes

    def self.record!(members_intent:)
      store.write(KEY, {"members_intent" => members_intent, "at" => Time.current.iso8601}, expires_in: STALE_AFTER)
    end

    # nil when no bot reported recently.
    def self.current
      store.read(KEY)
    end

    # Its own Redis store: Rails.cache is a null store in development unless
    # caching is switched on, and the bot and the web app are two processes.
    def self.store
      @store ||= ActiveSupport::Cache::RedisCacheStore.new(
        url: Rails.configuration.redis.url,
        db: Rails.configuration.redis.cache_db,
        namespace: "fleetyards-#{Rails.env}"
      )
    end
  end
end
