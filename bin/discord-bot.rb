#!/usr/bin/env ruby
# frozen_string_literal: true

# Long-running Discord Gateway listener that turns scheduled-event RSVPs
# into Fleetyards signups. Run as its own service alongside the web/sidekiq
# tier (single instance per Discord application).

require_relative "../config/environment"
require "discordrb"
require "discord/scheduled_event_rsvp_handler"

token = Discord::ApiClient.bot_token
abort("DISCORD_BOT_TOKEN missing") if token.blank?

Rails.logger = ActiveSupport::TaggedLogging.new(Logger.new($stdout)) if Rails.logger.nil?

bot = Discordrb::Bot.new(
  token: token,
  intents: %i[servers server_scheduled_events]
)

bot.scheduled_event_user_register do |event|
  result = Discord::ScheduledEventRsvpHandler.new(
    guild_id: event.server.id,
    scheduled_event_id: event.scheduled_event.id,
    discord_user_id: event.user.id
  ).add!
  Rails.logger.info("[discord-bot] add #{event.scheduled_event.id} ← #{event.user.id}: #{result.status} (#{result.detail})")
rescue => e
  Rails.logger.error("[discord-bot] add failed: #{e.class}: #{e.message}")
end

bot.scheduled_event_user_unregister do |event|
  result = Discord::ScheduledEventRsvpHandler.new(
    guild_id: event.server.id,
    scheduled_event_id: event.scheduled_event.id,
    discord_user_id: event.user.id
  ).remove!
  Rails.logger.info("[discord-bot] remove #{event.scheduled_event.id} ← #{event.user.id}: #{result.status} (#{result.detail})")
rescue => e
  Rails.logger.error("[discord-bot] remove failed: #{e.class}: #{e.message}")
end

Signal.trap("INT") { bot.stop }
Signal.trap("TERM") { bot.stop }

Rails.logger.info("[discord-bot] starting Gateway listener")
bot.run
