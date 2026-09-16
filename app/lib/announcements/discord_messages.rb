# frozen_string_literal: true

module Announcements
  # The ordered messages one announcement posts to a Discord channel.
  #
  # Authored parts go out verbatim and in order. Without them the body is
  # packed into as many messages as it takes, on paragraph boundaries -- which
  # is the part that used to be a `truncate(1_800)`, and what that did to a
  # 3,500-character launch announcement was drop the second half of it.
  class DiscordMessages
    def initialize(announcement)
      @announcement = announcement
    end

    def self.call(announcement)
      new(announcement).to_a
    end

    def to_a
      return @announcement.discord_parts if @announcement.authored_discord?

      composed
    end

    private def composed
      first, *rest = pack(body)
      return [] if first.blank?

      [[heading, first].compact_blank.join("\n"), *rest].tap do |messages|
        messages[-1] = [messages.last, link].compact_blank.join("\n") if link.present?
      end
    end

    # Paragraph by paragraph into messages that fit. A paragraph longer than
    # one message on its own is hard-split rather than dropped: losing a word
    # boundary is a cosmetic problem, losing the paragraph is not.
    private def pack(text)
      limit = Announcement::DISCORD_PART_LIMIT - RESERVED

      text.to_s.split(/\n{2,}/).each_with_object([]) do |paragraph, messages|
        paragraph.scan(/.{1,#{limit}}/m).each do |chunk|
          if messages.last.present? && messages.last.length + chunk.length + 2 <= limit
            messages[-1] = "#{messages.last}\n\n#{chunk}"
          else
            messages << chunk
          end
        end
      end
    end

    # Headroom for the heading on the first message and the link on the last,
    # neither of which is in the packed body.
    RESERVED = 200

    private def heading
      "**#{@announcement.title}**"
    end

    private def body
      @announcement.body
    end

    private def link
      @announcement.absolute_link
    end
  end
end
