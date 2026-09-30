# frozen_string_literal: true

module Discord
  # Discord caps a message at 2000 characters counted as UTF-16 code units, so
  # an emoji outside the basic plane is two of them while Ruby counts it as
  # one. A message measured with `length` can pass here and be refused there.
  module MessageLength
    MAX = 2000

    def self.of(text)
      text.to_s.encode("UTF-16LE").bytesize / 2
    end

    def self.fits?(text, max = MAX)
      of(text) <= max
    end

    def self.truncate(text, max = MAX)
      text = text.to_s
      return text if fits?(text, max)

      used = 0
      text.each_char.take_while { |char| (used += of(char)) <= max }.join
    end
  end
end
