# frozen_string_literal: true

require "discord/webhook"

# rubocop:disable Naming/AccessorMethodName
module Discord
  # An admin-written announcement, posted to the updates channel.
  class Announcement < ::Discord::Webhook
    # Discord's own cap is 2000 for the whole message; the title and the link
    # take the rest.
    MAX_MESSAGE_LENGTH = 1_800

    def self.configured?
      Rails.application.credentials.discord_updates_endpoint.present?
    end

    private def announcement
      options[:announcement]
    end

    private def get_title
      announcement.title
    end

    # The full body rather than the social one: Discord has 2000 characters to
    # play with and renders markdown, so the post that goes there is the
    # announcement itself, not the 280-character version of it written for X.
    private def get_message
      announcement.body.to_s.truncate(MAX_MESSAGE_LENGTH)
    end

    private def get_url
      announcement.absolute_link
    end
  end
end
# rubocop:enable Naming/AccessorMethodName
