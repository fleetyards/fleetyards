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

    private def platform
      Platform::DISCORD
    end

    # The heading rides on the first message and the link on the last, so each
    # is packed against the room its own extras leave rather than a guess at
    # what they might cost. A 255-character title is longer than any fixed
    # reserve worth setting, and the message it headed would have gone over.
    private def composed
      chunks = pack(body, platform.limit - [overhead(heading), overhead(link)].max)
      return [] if chunks.empty?

      chunks[0] = [heading, chunks[0]].compact_blank.join("\n")
      chunks[-1] = [chunks.last, link].compact_blank.join("\n")
      chunks
    end

    private def overhead(extra)
      return 0 if extra.blank?

      platform.length(extra) + 1
    end

    # Paragraph by paragraph into messages that fit. A paragraph longer than
    # one message on its own is hard-split rather than dropped: losing a word
    # boundary is a cosmetic problem, losing the paragraph is not.
    private def pack(text, limit)
      text.to_s.split(/\n{2,}/).each_with_object([]) do |paragraph, messages|
        split(paragraph, limit).each do |chunk|
          if messages.last.present? && platform.length(messages.last) + platform.length(chunk) + 2 <= limit
            messages[-1] = "#{messages.last}\n\n#{chunk}"
          else
            messages << chunk
          end
        end
      end
    end

    # Sliced by what the platform charges, not by cluster count: a paragraph of
    # 2,000 emoji is 2,000 clusters and 4,000 code units, and Discord counts
    # the latter. Never mid-cluster, so nothing is cut in half.
    private def split(paragraph, limit)
      return [paragraph] if platform.length(paragraph) <= limit

      paragraph.each_grapheme_cluster.each_with_object([+""]) do |cluster, chunks|
        chunks << +"" if platform.length(chunks.last + cluster) > limit && chunks.last.present?
        chunks[-1] << cluster
      end
    end

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
