# frozen_string_literal: true

module Rsi
  # An organisation's Spectrum Identification, as RSI prints it in the org's
  # page title: up to ten capitals and digits.
  #
  # Fleets have typed it every way the org page offers -- the SID, the page's
  # URL with or without the scheme and the locale, `[SID]` as it is shown in
  # chat -- so those are reduced to the SID. Anything else (a citizen handle, a
  # citizen record number, the org's name) is left as it was, for the format
  # check to reject rather than for a guess to turn into some other org's SID.
  module Sid
    FORMAT = /\A[A-Z0-9]{1,10}\z/

    ORG_URL = %r{\A(?:https?://)?(?:www\.)?robertsspaceindustries\.com/(?:[a-z]{2}/)?orgs/([^/?#\s]+)}i

    def self.normalize(value)
      return if value.nil?

      sid = value.to_s.strip
      sid = Regexp.last_match(1) if sid.match(ORG_URL)
      sid = sid.delete_suffix("/")
      sid = sid[1..-2] if sid.start_with?("[") && sid.end_with?("]")

      sid.upcase.presence
    end

    def self.valid?(value)
      FORMAT.match?(value.to_s)
    end
  end
end
