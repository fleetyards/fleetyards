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

    # Split across as many messages as the preview needs, never truncated. A
    # dry run whose job is to show every part cannot be the one thing that
    # drops the last of them -- and a long announcement's X posts sit at the
    # bottom, which is exactly what a cut would take.
    private def contents
      blocks = [
        "**#{title}**",
        I18n.t("announcements.preview.channels", channels: channel_list),
        *discord_preview,
        *social_preview(:bluesky),
        *social_preview(:x)
      ].compact_blank

      pack(blocks)
    end

    # Never mid-block, so a quoted post is not split down the middle. A single
    # block past the cap is trimmed on its own -- it is a preview of copy the
    # model already refused to save.
    private def pack(blocks)
      limit = ::Announcements::Platform::DISCORD.limit

      blocks.each_with_object([]) do |block, messages|
        block = ::Announcements::Platform::DISCORD.truncate(block, to: limit) if ::Announcements::Platform::DISCORD.length(block) > limit

        if messages.last.present? && ::Announcements::Platform::DISCORD.length(messages.last) + ::Announcements::Platform::DISCORD.length(block) + 1 <= limit
          messages[-1] = "#{messages.last}\n#{block}"
        else
          messages << block
        end
      end
    end

    # The parent builds this from the composed Discord messages; the preview
    # quotes those itself, block by block.
    private def get_message
      nil
    end

    private def discord_preview
      return [] unless announcement.post_discord?

      preview_blocks(::Announcements::Platform::DISCORD, messages)
    end

    # Counted the way each platform counts -- X weights CJK and emoji and
    # discounts URLs, Bluesky counts graphemes -- because a number that does
    # not match the platform's own is worse than no number.
    private def social_preview(channel)
      return [] unless announcement.public_send(:"post_#{channel}")

      platform = ::Announcements::Platform.for(channel)

      preview_blocks(platform, Announcements::SocialPosts.call(announcement, platform:))
    end

    private def preview_blocks(platform, parts)
      parts.map.with_index(1) do |part, position|
        [
          heading(
            I18n.t("announcements.channels.#{platform.key}"),
            position, parts.size, platform.length(part), platform.limit
          ),
          quote(part)
        ].join("\n")
      end
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
