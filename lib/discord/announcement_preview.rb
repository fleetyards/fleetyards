# frozen_string_literal: true

require "bsky/post"
require "discord/announcement"
require "x_com/post"

# rubocop:disable Naming/AccessorMethodName
module Discord
  # The dry run: the same announcement, posted to the admin channel instead of
  # the updates channel.
  #
  # It carries the other channels' copy too -- every post of the Bluesky thread
  # and every post of the X thread, each with its character count -- because
  # that is the part nobody can check by reading the form. Where a thread
  # breaks and what each post costs against its platform's limit is the whole
  # question, and the only honest answer is the composed strings.
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

    # One message, however many the real post would be: a dry run that spanned
    # three messages in the admin channel would be harder to read than the
    # thing it is previewing. The parent posts its composed messages one after
    # another, so this puts the single preview back.
    private def contents
      [content]
    end

    private def get_message
      [
        I18n.t("announcements.preview.channels", channels: channel_list),
        "",
        *discord_preview,
        *social_preview(:bluesky, ::Bsky::Post::MAX_LENGTH),
        *social_preview(:x, ::XCom::Post::MAX_LENGTH)
      ].compact_blank.join("\n").truncate(::Announcement::DISCORD_PART_LIMIT - 200)
    end

    private def discord_preview
      return [] unless announcement.post_discord?

      messages.flat_map.with_index(1) do |message, position|
        [
          heading(
            I18n.t("announcements.channels.discord"),
            position, messages.size, message.length, ::Announcement::DISCORD_PART_LIMIT
          ),
          quote(message)
        ]
      end
    end

    private def social_preview(channel, limit)
      return [] unless announcement.public_send(:"post_#{channel}")

      posts = Announcements::SocialPosts.call(announcement, limit:)

      posts.flat_map.with_index(1) do |post, position|
        [
          heading(
            I18n.t("announcements.channels.#{channel}"),
            position, posts.size, length_for(channel, post), limit
          ),
          quote(post)
        ]
      end
    end

    # X bills a URL at 23 characters whatever its real length, so the same
    # string costs differently on the two platforms.
    private def length_for(channel, post)
      (channel == :x) ? ::XCom::Post.weighted_length(post) : post.length
    end

    private def heading(channel, position, total, count, limit)
      key = (total > 1) ? "part_heading" : "social_heading"

      I18n.t("announcements.preview.#{key}", channel:, position:, total:, count:, limit:)
    end

    private def quote(text)
      "> #{text.gsub("\n", "\n> ")}"
    end

    private def channel_list
      announcement.channels
        .map { |channel| I18n.t("announcements.channels.#{channel}") }
        .join(", ")
    end
  end
end
# rubocop:enable Naming/AccessorMethodName
