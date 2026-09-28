# frozen_string_literal: true

require "discord/webhook"
require "faraday"

# rubocop:disable Naming/AccessorMethodName
module Discord
  # An admin-written announcement, posted to the updates channel.
  class Announcement < ::Discord::Webhook
    def self.configured?
      Rails.application.credentials.discord_updates_endpoint.present?
    end

    private def announcement
      options[:announcement]
    end

    private def get_title
      announcement.title
    end

    # Kept for the preview, which quotes the first message. The posting path
    # goes through `contents`.
    private def get_message
      messages.first
    end

    # The composer has already placed the title and the link -- in the author's
    # own parts when they wrote them, and around the packed body when they did
    # not -- so there is nothing left for the base class to wrap around it.
    private def contents
      messages
    end

    private def messages
      @messages ||= Announcements::DiscordMessages.call(announcement)
    end

    private def get_url
      nil
    end

    # The message ids are what its reactions are read back from.
    private def wait?
      true
    end

    # A webhook's message carries no guild id, and the post's jump link needs
    # one. The webhook's own URL answers it without a bot token, so the link
    # exists from the moment the post does rather than after a refresh.
    private def created_message(response)
      message = super
      return message if message.blank? || message["guild_id"].present? || guild_id.blank?

      message.merge("guild_id" => guild_id)
    end

    GUILD_LOOKUP_TIMEOUT = 5

    private def guild_id
      return @guild_id if defined?(@guild_id)

      @guild_id = begin
        response = Faraday.new(request: {timeout: GUILD_LOOKUP_TIMEOUT, open_timeout: GUILD_LOOKUP_TIMEOUT})
          .get(@webhook_endpoint)
        response.success? ? JSON.parse(response.body.to_s)["guild_id"] : nil
      rescue Faraday::Error, JSON::ParserError
        nil
      end
    end
  end
end
# rubocop:enable Naming/AccessorMethodName
