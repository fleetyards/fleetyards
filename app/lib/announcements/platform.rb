# frozen_string_literal: true

module Announcements
  # How each platform counts, and how to cut to its limit.
  #
  # Neither counts characters the way Ruby does. X weights codepoints and
  # discounts URLs; Bluesky counts grapheme clusters. Using `String#length` for
  # either shows an author a post is fine when the platform rejects it, and cuts
  # emoji in half when it trims.
  class Platform
    attr_reader :key, :limit

    def initialize(key, limit)
      @key = key
      @limit = limit
    end

    def self.for(key)
      case key.to_sym
      when :x then X
      when :bluesky then BLUESKY
      when :discord then DISCORD
      else raise ArgumentError, "unknown platform #{key}"
      end
    end

    def length(text)
      raise NotImplementedError
    end

    def fits?(text)
      length(text) <= limit
    end

    # Cut to `limit` as this platform counts, never mid-character. The ellipsis
    # is part of the budget.
    def truncate(text, to: limit)
      return text if length(text) <= to

      # The ellipsis is budgeted at what this platform charges for it, not at
      # one. U+2026 sits outside X's light ranges, so it weighs two there --
      # which is an off-by-one that only shows up on a post already at the cap.
      budget = to - length(ELLIPSIS)
      kept = +""

      text.each_grapheme_cluster do |cluster|
        break if length(kept + cluster) > budget

        kept << cluster
      end

      kept.rstrip + ELLIPSIS
    end

    ELLIPSIS = "…"

    # X counts in weighted units of 1/100th of a character, so a codepoint
    # worth 100 is one character and one worth 200 is two. Latin and the
    # punctuation ranges beside it are light; everything else -- CJK above all
    # -- is heavy. See twitter-text's config v3.
    class Weighted < Platform
      SCALE = 100
      DEFAULT_WEIGHT = 200
      LIGHT_WEIGHT = 100

      # The ranges twitter-text v3 gives a weight of 100.
      LIGHT_RANGES = [0..4351, 8192..8205, 8208..8223, 8242..8247].freeze

      # A URL is billed at a flat 23 characters whatever its real length,
      # because X wraps it through t.co.
      URL_LENGTH = 23
      URL_PATTERN = %r{https?://\S+}

      # X's extractor stops before trailing punctuation, so a sentence-final
      # full stop is text at its own weight rather than free inside the 23.
      # Stripping it here counts it separately, which is both what X does and
      # the safe direction to be wrong in.
      URL_TRAILING = /[.,;:!?'"’”)\]}>]+\z/

      # An emoji is one unit however many codepoints spell it: a ZWJ family and
      # a heart with a variation selector are both two characters to X, not
      # five and two.
      EMOJI_CODEPOINTS = [
        0x200D, 0xFE0F, 0x20E3,
        0x2190..0x21FF, 0x2300..0x23FF, 0x2600..0x27BF, 0x2B00..0x2BFF,
        0x1F000..0x1FAFF
      ].freeze

      def length(text)
        return 0 if text.blank?

        weight = 0
        scan(text) do |token, url|
          weight += url ? URL_LENGTH * SCALE : token_weight(token)
        end

        weight / SCALE
      end

      private def scan(text)
        position = 0

        text.scan(URL_PATTERN) do
          match = Regexp.last_match
          url = match[0].sub(URL_TRAILING, "")
          # A URL that was nothing but a scheme and punctuation is not a URL.
          next if url.blank?

          yield(text[position...match.begin(0)], false) if match.begin(0) > position
          yield(url, true)
          position = match.begin(0) + url.length
        end

        yield(text[position..], false) if position < text.length
      end

      private def token_weight(token)
        token.to_s.each_grapheme_cluster.sum { |cluster| cluster_weight(cluster) }
      end

      private def cluster_weight(cluster)
        return DEFAULT_WEIGHT if emoji?(cluster)

        cluster.each_codepoint.sum { |codepoint| codepoint_weight(codepoint) }
      end

      private def emoji?(cluster)
        cluster.each_codepoint.any? do |codepoint|
          EMOJI_CODEPOINTS.any? { |range| range.is_a?(Range) ? range.cover?(codepoint) : range == codepoint }
        end
      end

      private def codepoint_weight(codepoint)
        (LIGHT_RANGES.any? { |range| range.cover?(codepoint) }) ? LIGHT_WEIGHT : DEFAULT_WEIGHT
      end
    end

    # Bluesky counts grapheme clusters, so an emoji is one whatever it is made
    # of.
    class Graphemes < Platform
      def length(text)
        text.to_s.grapheme_clusters.size
      end
    end

    # Discord counts UTF-16 code units -- JavaScript's own string length -- so
    # anything above the BMP costs two. 2,000 rockets are 2,000 graphemes and
    # 4,000 code units, and Discord rejects the message.
    class Utf16 < Platform
      def length(text)
        text.to_s.each_char.sum { |char| (char.ord > 0xFFFF) ? 2 : 1 }
      end
    end

    X = Weighted.new(:x, 280)
    BLUESKY = Graphemes.new(:bluesky, 300)
    DISCORD = Utf16.new(:discord, 2_000)

    SOCIAL = [X, BLUESKY].freeze
  end
end
