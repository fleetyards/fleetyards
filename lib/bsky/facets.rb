# frozen_string_literal: true

module Bsky
  # Bluesky renders a post's text as plain text. A link or a hashtag is only
  # clickable when the record carries a facet naming its range, and the range
  # is in UTF-8 bytes, not characters.
  module Facets
    URL_PATTERN = ::Announcements::Platform::Weighted::URL_PATTERN
    URL_TRAILING = ::Announcements::Platform::Weighted::URL_TRAILING

    # A tag starts after whitespace or at the start of the text, and is not a
    # number: "#1" is a list item, not a tag.
    TAG_PATTERN = /(?<=\A|\s)#([^\s#]*[^\d\s\p{P}][^\s#]*)/
    TAG_TRAILING = /\p{P}+\z/
    TAG_MAX_LENGTH = 64

    def self.extract(text)
      (links(text) + tags(text)).sort_by { |facet| facet.dig("index", "byteStart") }
    end

    def self.links(text)
      matches(text, URL_PATTERN).filter_map do |start, url|
        url = url.sub(URL_TRAILING, "")
        next if url.blank?

        facet(text, start, url, "$type" => "app.bsky.richtext.facet#link", "uri" => url)
      end
    end

    def self.tags(text)
      matches(text, TAG_PATTERN).filter_map do |start, hashtag|
        tag = hashtag.delete_prefix("#").sub(TAG_TRAILING, "")
        next if tag.blank? || tag.grapheme_clusters.size > TAG_MAX_LENGTH

        facet(text, start, "##{tag}", "$type" => "app.bsky.richtext.facet#tag", "tag" => tag)
      end
    end

    def self.matches(text, pattern)
      result = []
      text.scan(pattern) { result << [Regexp.last_match.begin(0), Regexp.last_match[0]] }
      result
    end

    def self.facet(text, start, token, feature)
      byte_start = text[0...start].bytesize

      {
        "index" => {"byteStart" => byte_start, "byteEnd" => byte_start + token.bytesize},
        "features" => [feature]
      }
    end

    private_class_method :links, :tags, :matches, :facet
  end
end
