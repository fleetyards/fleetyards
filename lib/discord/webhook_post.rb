# frozen_string_literal: true

require "discord/message_length"
require "discordrb/webhooks"

module Discord
  # One message through a fleet's own webhook, for a fleet that set one up but
  # never picked an announcement channel for the bot.
  class WebhookPost
    HOSTS = %w[discord.com discordapp.com canary.discord.com ptb.discord.com].freeze

    # The worker POSTs to whatever a fleet saved here, so only a Discord
    # webhook URL is ever called; anything else could aim it at an internal host.
    def self.allowed_url?(url)
      uri = URI.parse(url.to_s)

      uri.is_a?(URI::HTTPS) && uri.port == URI::HTTPS::DEFAULT_PORT && uri.userinfo.nil? &&
        HOSTS.include?(uri.host.to_s.downcase) && uri.path.start_with?("/api/webhooks/")
    rescue URI::InvalidURIError
      false
    end

    def initialize(url)
      @url = url
    end

    def deliver(content, image_url: nil)
      return false unless self.class.allowed_url?(@url)

      Discordrb::Webhooks::Client.new(url: @url).execute do |builder|
        builder.content = MessageLength.truncate(content)
        builder.allowed_mentions = {parse: []}
        builder.add_embed { |embed| embed.image = Discordrb::Webhooks::EmbedImage.new(url: image_url) } if image_url.present?
      end
      true
    end
  end
end
