# frozen_string_literal: true

module Announcements
  # How each platform counts, and how to cut to its limit.
  #
  # Neither counts characters the way Ruby does. Bluesky counts grapheme
  # clusters, Discord UTF-16 code units. Using `String#length` for either shows
  # an author a post is fine when the platform rejects it, and cuts emoji in
  # half when it trims.
  class Platform
    attr_reader :key, :limit

    def initialize(key, limit)
      @key = key
      @limit = limit
    end

    def self.for(key)
      case key.to_sym
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
      # one.
      budget = to - length(ELLIPSIS)
      kept = +""

      text.each_grapheme_cluster do |cluster|
        break if length(kept + cluster) > budget

        kept << cluster
      end

      kept.rstrip + ELLIPSIS
    end

    ELLIPSIS = "…"

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

    BLUESKY = Graphemes.new(:bluesky, 300)
    DISCORD = Utf16.new(:discord, 2_000)
  end
end
