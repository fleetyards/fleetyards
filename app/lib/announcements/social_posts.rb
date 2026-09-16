# frozen_string_literal: true

module Announcements
  # The ordered posts one announcement makes on a social platform. One entry is
  # a single post; two or more are a thread, each replying to the one before.
  #
  # When the author wrote the parts they are posted verbatim -- where the break
  # falls, and which post carries the link, are editorial decisions, and a
  # composer that re-wraps them would move the boundary somebody chose. When
  # they did not, this falls back to the one composed post a short announcement
  # wants: title, first paragraph, link.
  class SocialPosts
    ELLIPSIS = "…"

    def initialize(announcement, limit:)
      @announcement = announcement
      @limit = limit
    end

    def self.call(announcement, limit:)
      new(announcement, limit:).to_a
    end

    def to_a
      return authored if @announcement.authored_social?

      [composed].compact_blank
    end

    # Trimmed rather than trusted, even though the model validates each part:
    # the model's bound is Bluesky's 300 and X stops at 280, so a post that is
    # legal on one platform can arrive here too long for the other.
    private def authored
      @announcement.social_parts.map { |part| truncate(part, @limit) }
    end

    private def composed
      [headline, link].compact_blank.join("\n\n")
    end

    # The link is never truncated -- a cut URL is not a link, and the body is
    # the part a reader can lose without losing the way to the rest.
    private def headline
      return nil if body_budget <= 0

      truncate([@announcement.title, body].compact_blank.join("\n\n"), body_budget)
    end

    private def body_budget
      return @limit if link.blank?

      @limit - link.length - 2
    end

    private def body
      self.class.plain_text(@announcement.body).split("\n\n").first
    end

    private def link
      @announcement.absolute_link
    end

    private def truncate(text, limit)
      return text if text.length <= limit

      text[0, limit - 1].rstrip + ELLIPSIS
    end

    # Markdown as words. A social post has no renderer behind it, so the
    # syntax would ship literally -- asterisks and all -- if it were passed
    # straight through.
    def self.plain_text(markdown)
      return "" if markdown.blank?

      markdown
        .gsub(/!\[[^\]]*\]\([^)]*\)/, "")
        .gsub(/\[([^\]]*)\]\([^)]*\)/, '\1')
        .gsub(/^\s{0,3}\#{1,6}\s+/, "")
        .gsub(/^\s{0,3}>\s?/, "")
        .gsub(/^\s*[-*+]\s+/, "")
        .gsub(/(\*\*|__)(.*?)\1/m, '\2')
        .gsub(/(\*|_)(.*?)\1/m, '\2')
        .gsub(/`{1,3}([^`]*)`{1,3}/m, '\1')
        .gsub(/\n{3,}/, "\n\n")
        .strip
    end
  end
end
