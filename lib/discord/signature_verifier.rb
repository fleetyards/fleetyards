# frozen_string_literal: true

module Discord
  # Verifies the Ed25519 signature Discord puts on every interaction request.
  #
  # This is the only thing standing between the public, session-less
  # interactions endpoint and the app, so it verifies the *raw* request body:
  # Rails' parsed and re-serialised params are a different byte sequence and
  # would never match the signature.
  #
  # OpenSSL rather than the ed25519 gem on purpose. The gem is in Gemfile.lock,
  # but only as a transitive dependency of the SSH stack Kamal uses -- a
  # `bundle update` that drops it would silently take this boundary with it.
  class SignatureVerifier
    # Discord's own guidance. Bounds how long a captured request stays
    # replayable; the signature itself never expires.
    MAX_AGE = 5.minutes

    SIGNATURE_HEADER = "HTTP_X_SIGNATURE_ED25519"
    TIMESTAMP_HEADER = "HTTP_X_SIGNATURE_TIMESTAMP"

    HEX = /\A[0-9a-f]+\z/i

    def self.public_key
      Rails.application.config.app.discord[:public_key].presence
    end

    def self.configured?
      public_key.present?
    end

    def initialize(public_key: self.class.public_key)
      @public_key = public_key
    end

    def valid?(signature:, timestamp:, body:)
      return false if @public_key.blank? || signature.blank? || timestamp.blank?
      return false unless fresh?(timestamp)

      verify_key.verify(nil, decode(signature), "#{timestamp}#{body}")
    rescue OpenSSL::OpenSSLError, ArgumentError, TypeError
      false
    end

    # A timestamp is a unix epoch second. Reject the future too: a clock-skewed
    # or hand-crafted timestamp far ahead would otherwise stay valid for as
    # long as it is ahead.
    private def fresh?(timestamp)
      seconds = Integer(timestamp, 10)
      age = Time.current.to_i - seconds

      age.abs <= MAX_AGE.to_i
    rescue ArgumentError, TypeError
      false
    end

    private def decode(hex)
      raise ArgumentError, "not hex" unless hex.match?(HEX) && hex.length.even?

      [hex].pack("H*")
    end

    private def verify_key
      @verify_key ||= OpenSSL::PKey.new_raw_public_key("ED25519", decode(@public_key))
    end
  end
end
