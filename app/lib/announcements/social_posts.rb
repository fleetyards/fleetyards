# frozen_string_literal: true

module Announcements
  # The ordered posts one announcement makes on a social platform. One entry is
  # a single post; two or more are a thread, each replying to the one before.
  #
  # Authored parts come back **unchanged**. Where the break falls and which post
  # carries the link are editorial decisions, and trimming one on the way out
  # would silently rewrite copy somebody measured -- the model validates each
  # part against the platforms the announcement selected, so an over-long post
  # is refused at save rather than cut at post.
  #
  # Without parts this falls back to the one composed post a short announcement
  # wants: title, first paragraph, link. That one is trimmed, because nobody
  # wrote it to a limit.
  class SocialPosts
    def initialize(announcement, platform:)
      @announcement = announcement
      @platform = platform
    end

    def self.call(announcement, platform:)
      new(announcement, platform:).to_a
    end

    def to_a
      return @announcement.social_parts if @announcement.authored_social?

      [composed].compact_blank
    end

    private def composed
      [headline, link].compact_blank.join("\n\n")
    end

    # The link is never truncated -- a cut URL is not a link, and the body is
    # the part a reader can lose without losing the way to the rest.
    private def headline
      return nil if body_budget <= 0

      @platform.truncate([@announcement.title, body].compact_blank.join("\n\n"), to: body_budget)
    end

    private def body_budget
      return @platform.limit if link.blank?

      @platform.limit - @platform.length(link) - 2
    end

    private def body
      self.class.plain_text(@announcement.body).split("\n\n").first
    end

    private def link
      @announcement.absolute_link
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
