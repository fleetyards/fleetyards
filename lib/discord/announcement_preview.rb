# frozen_string_literal: true

require "bsky/post"
require "discord/announcement"
require "x_com/post"

# rubocop:disable Naming/AccessorMethodName
module Discord
  # The dry run: the same announcement, posted to the admin channel instead of
  # the updates channel.
  #
  # It carries the other channels' copy too -- the Bluesky post, the X post,
  # each with its character count -- because that is the part nobody can check
  # by reading the form. The composer truncates against a limit, and the only
  # honest way to see what a reader will get is to see the composed string.
  class AnnouncementPreview < ::Discord::Announcement
    def self.configured?
      Rails.application.credentials.discord_admin_endpoint.present?
    end

    private def get_webhook_endpoint
      Rails.application.credentials.discord_admin_endpoint
    end

    private def get_title
      I18n.t("announcements.preview.title", title: announcement.title)
    end

    private def get_message
      [
        I18n.t("announcements.preview.channels", channels: channel_list),
        "",
        super,
        "",
        social_preview(:bluesky, ::Bsky::Post::MAX_LENGTH),
        social_preview(:x, ::XCom::Post::MAX_LENGTH)
      ].compact_blank.join("\n")
    end

    private def social_preview(channel, limit)
      return nil unless announcement.public_send(:"post_#{channel}")

      text = Announcements::SocialMessage.call(announcement, limit:)

      [
        I18n.t(
          "announcements.preview.social_heading",
          channel: I18n.t("announcements.channels.#{channel}"),
          count: text.length,
          limit: limit
        ),
        "> #{text.gsub("\n", "\n> ")}"
      ].join("\n")
    end

    private def channel_list
      announcement.channels
        .map { |channel| I18n.t("announcements.channels.#{channel}") }
        .join(", ")
    end
  end
end
# rubocop:enable Naming/AccessorMethodName
