# frozen_string_literal: true

require "discord/api_client"

module Discord
  # One message to one guild channel, posted by the bot.
  #
  # A channel somebody deleted or locked the bot out of answers 404 or 403.
  # Neither changes on a retry, and the fleet finds out from its settings page
  # rather than from a job that fails every time an event is announced.
  class ChannelPost
    MAX_LENGTH = 2000

    def initialize(channel_id, api: nil)
      @channel_id = channel_id
      @api = api
    end

    def deliver(content)
      api.create_message(@channel_id, {content: content.to_s.first(MAX_LENGTH), allowed_mentions: {parse: []}})
      true
    rescue ApiClient::Error => e
      raise unless [403, 404].include?(e.status)

      Rails.logger.info("[Discord::ChannelPost] channel=#{@channel_id} not delivered: #{e.status}")
      false
    end

    private def api
      @api ||= ApiClient.new
    end
  end
end
