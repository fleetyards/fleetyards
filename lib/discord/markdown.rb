# frozen_string_literal: true

module Discord
  # Text somebody typed, set inside Discord markdown. An event title holding
  # `](` would otherwise close the link it sits in and open one of its own.
  module Markdown
    def self.escape(text)
      text.to_s.gsub(/([\\\[\]()*_~`|>])/) { "\\#{$1}" }
    end
  end
end
