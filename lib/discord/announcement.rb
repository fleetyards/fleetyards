# frozen_string_literal: true

require "discord/webhook"

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
  end
end
# rubocop:enable Naming/AccessorMethodName
