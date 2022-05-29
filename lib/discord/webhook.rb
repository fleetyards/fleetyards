# frozen_string_literal: true

require 'discordrb/webhooks'

# rubocop:disable Naming/AccessorMethodName
module Discord
  class Webhook
    include Routing

    attr_accessor :webhook_endpoint, :options, :title, :message, :url

    def initialize(options = {})
      @webhook_endpoint = get_webhook_endpoint
      @options = options
      @title = get_title
      @message = get_message
      @url = get_url
    end

    def run
      return if @webhook_endpoint.blank?

      client.execute do |builder|
        builder.content = content
      end
    end

    private def get_webhook_endpoint
      Rails.application.credentials.discord_updates_endpoint
    end

    private def get_message; end

    private def get_title
      raise NotImplementedError
    end

    private def get_url
      raise NotImplementedError
    end

    private def content
      [
        "**#{title}**",
        message,
        url,
      ].compact.join("\n")
    end

    private def client
      @client ||= Discordrb::Webhooks::Client.new(url: @webhook_endpoint)
    end
  end
end
# rubocop:enable Naming/AccessorMethodName
