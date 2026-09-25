# frozen_string_literal: true

require "discord/message_length"
require "discord/api_client"

module Discord
  # One message to one guild channel, posted by the bot.
  #
  # The channel is looked up first and has to belong to the fleet's own guild.
  # An id is only ever a string somebody saved: it can name a channel in
  # another server the bot is in, or one left behind when the fleet moved to a
  # new server, and either would hand the fleet's events to strangers.
  #
  # A channel that is gone, locked to the bot or not a channel at all answers
  # 404, 403 or 400. None of them changes on a retry, so the post is dropped and
  # the fleet finds out from its Discord settings rather than from a job that
  # fails every time an event is announced.
  class ChannelPost
    UNDELIVERABLE_STATUSES = [400, 403, 404].freeze

    def initialize(channel_id, guild_id:, api: nil)
      @channel_id = channel_id
      @guild_id = guild_id
      @api = api
    end

    # The message Discord created, or false when the post was dropped.
    def deliver(content, components: nil)
      return skip("no guild bound") if @guild_id.blank?
      return skip("channel belongs to another guild") unless api.get_channel(@channel_id)&.dig("guild_id") == @guild_id

      payload = {content: MessageLength.truncate(content), allowed_mentions: {parse: []}}
      payload[:components] = components if components.present?

      api.create_message(@channel_id, payload)
    rescue ApiClient::Error => e
      raise unless UNDELIVERABLE_STATUSES.include?(e.status)

      skip(e.status)
    end

    private def skip(reason)
      Rails.logger.warn("[Discord::ChannelPost] channel=#{@channel_id} not delivered: #{reason}")
      false
    end

    private def api
      @api ||= ApiClient.new
    end
  end
end
