# frozen_string_literal: true

require "discordrb/webhooks"

# rubocop:disable Naming/AccessorMethodName
module Discord
  class Webhook
    include RoutingConcern

    attr_accessor :webhook_endpoint, :options, :title, :message, :url

    def initialize(options = {})
      # Options first: get_webhook_endpoint is an override point, and a
      # subclass whose endpoint depends on its options -- a per-fleet webhook
      # rather than the global announcements one -- cannot read them otherwise.
      @options = options
      @from = options.fetch(:from, 0)
      @webhook_endpoint = get_webhook_endpoint
      @title = get_title
      @message = get_message
      @url = get_url
    end

    # Posted one execute at a time and in order, because an announcement is not
    # always one message: Discord caps a message at 2000 characters, and a
    # launch that runs past it is two messages whose order is the whole point.
    # A subclass with one message overrides nothing.
    #
    # `from` resumes a run that died partway. Discord cannot unsend a message,
    # so an attempt that posted the first of three and then failed has to carry
    # on from the second rather than start again. The block is called with each
    # index as it lands, which is how the caller knows where that is.
    def run
      return if @webhook_endpoint.blank?

      bodies = contents.compact_blank

      bodies.each_with_index do |body, index|
        next if index < @from

        client.execute do |builder|
          builder.content = body
          builder.allowed_mentions = allowed_mentions if allowed_mentions
        end

        yield(index) if block_given?
      end
    end

    private def contents
      [content]
    end

    private def get_webhook_endpoint
      Rails.application.credentials.discord_updates_endpoint
    end

    private def get_message
    end

    private def allowed_mentions
    end

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
        url
      ].compact.join("\n")
    end

    private def client
      @client ||= Discordrb::Webhooks::Client.new(url: @webhook_endpoint)
    end
  end
end
# rubocop:enable Naming/AccessorMethodName
