# frozen_string_literal: true

module Announcements
  # Builds the text of a social post for a given character limit.
  #
  # One composer for both platforms rather than one each, because the only
  # thing that differs between an X post and a Bluesky post is the number.
  class SocialMessage
    ELLIPSIS = "…"

    def initialize(announcement, limit:)
      @announcement = announcement
      @limit = limit
    end

    def self.call(announcement, limit:)
      new(announcement, limit:).to_s
    end

    def to_s
      [headline, link].compact_blank.join("\n\n")
    end

    # The link is never truncated -- a cut URL is not a link, and the body is
    # the part a reader can lose without losing the way to the rest.
    private def headline
      return nil if body_budget <= 0

      text = [@announcement.title, body].compact_blank.join("\n\n")
      return text if text.length <= body_budget

      text[0, body_budget - 1].rstrip + ELLIPSIS
    end

    private def body_budget
      return @limit if link.blank?

      @limit - link.length - 2
    end

    private def body
      return @announcement.social_body if @announcement.social_body.present?

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
