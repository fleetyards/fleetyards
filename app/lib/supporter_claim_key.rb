# frozen_string_literal: true

# The token a supporter puts in a donation so the payment can be matched to
# their account.
#
# Crockford base32: no I, L, O or U, so the alphabet survives being read off a
# screen and typed into a payment form by hand. Decoding folds the characters
# people substitute anyway -- I and L read as 1, O reads as 0 -- which means a
# key transcribed slightly wrong still resolves instead of silently failing.
class SupporterClaimKey
  ALPHABET = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
  PREFIX = "FY"
  GROUP_LENGTH = 4
  GROUPS = 2

  # Folded on the way in, never generated: the alphabet excludes all three.
  AMBIGUOUS = {"I" => "1", "L" => "1", "O" => "0"}.freeze

  # Matches a key anywhere in free text, with or without its separators, so a
  # donor message reading "for my fleet - FY7K2M9QXD thanks!" still resolves.
  PATTERN = /#{PREFIX}[-\s]?[#{ALPHABET}ILO]{#{GROUP_LENGTH}}[-\s]?[#{ALPHABET}ILO]{#{GROUP_LENGTH}}/i

  def self.generate
    groups = Array.new(GROUPS) do
      Array.new(GROUP_LENGTH) { ALPHABET[SecureRandom.random_number(ALPHABET.length)] }.join
    end

    [PREFIX, *groups].join("-")
  end

  # The canonical stored form. Returns nil for anything that is not key-shaped,
  # so a caller can treat "no key here" and "a key that matches nobody" as the
  # different things they are.
  #
  # A bare body is accepted, which makes an eight-character input beginning "FY"
  # ambiguous -- it is read as the body. Unavoidable while the bare form is
  # allowed, and harmless: the keys are 40 bits, so a mistyped one resolves to
  # nobody rather than to somebody else.
  def self.normalize(value)
    return if value.blank?

    body = value.to_s.upcase.gsub(/[^A-Z0-9]/, "")
    # Only when there is a prefix to strip: a key whose own body begins FY --
    # "FY-FYAB-CDEF" -- must not lose four characters of itself when it arrives
    # without the prefix.
    body = body.delete_prefix(PREFIX) if body.length == PREFIX.length + GROUP_LENGTH * GROUPS
    body = body.chars.map { |char| AMBIGUOUS.fetch(char, char) }.join

    return unless body.match?(/\A[#{ALPHABET}]{#{GROUP_LENGTH * GROUPS}}\z/)

    [PREFIX, *body.scan(/.{#{GROUP_LENGTH}}/o)].join("-")
  end

  # Pulls the first key out of a free-text donation message.
  def self.extract(text)
    return if text.blank?

    normalize(text.to_s[PATTERN])
  end
end
