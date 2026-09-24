# frozen_string_literal: true

require "discord/message_length"
require "discordrb/webhooks"

module Discord
  # One message through a fleet's own webhook, for a fleet that set one up but
  # never picked an announcement channel for the bot.
  class WebhookPost
    def initialize(url)
      @url = url
    end

    def deliver(content)
      Discordrb::Webhooks::Client.new(url: @url).execute do |builder|
        builder.content = MessageLength.truncate(content)
        builder.allowed_mentions = {parse: []}
      end
      true
    end
  end
end
