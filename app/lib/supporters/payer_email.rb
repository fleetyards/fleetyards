# frozen_string_literal: true

module Supporters
  # The forms of an address that reach the same inbox, for matching a payer to
  # an account. Google hands out gmail.com and googlemail.com as one mailbox,
  # and which of the two a donor's payment platform has on file is an accident
  # of when and where they signed up there.
  #
  # Dots and plus tags are left alone: folding those would need the stored
  # account addresses folded as well, which an equality lookup cannot do.
  module PayerEmail
    GMAIL_DOMAINS = %w[gmail.com googlemail.com].freeze

    def self.normalize(address)
      address.to_s.strip.downcase.presence
    end

    def self.variants(address)
      email = normalize(address)
      return [] if email.nil?

      local, domain = email.split("@", 2)
      return [email] unless GMAIL_DOMAINS.include?(domain)

      [email, *(GMAIL_DOMAINS - [domain]).map { |alias_domain| "#{local}@#{alias_domain}" }]
    end
  end
end
