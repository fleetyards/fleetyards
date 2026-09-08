# frozen_string_literal: true

module Middleware
  # Bots and broken clients send header bytes that are not valid UTF-8. Rack and
  # Rails feed those bytes straight into regexps, `String#split` and `blank?`,
  # all of which raise `ArgumentError: invalid byte sequence in UTF-8` from deep
  # inside gem code — a 500 wherever the request happens to touch the header
  # first. Drop the invalid bytes before anything reads them.
  class ScrubHeaderEncoding
    SCRUBBED_HEADERS = %w[
      HTTP_ACCEPT
      HTTP_ACCEPT_ENCODING
      HTTP_ACCEPT_LANGUAGE
      HTTP_COOKIE
      HTTP_HOST
      HTTP_ORIGIN
      HTTP_REFERER
      HTTP_USER_AGENT
      HTTP_X_FORWARDED_FOR
      HTTP_X_FORWARDED_HOST
      HTTP_X_REQUESTED_WITH
    ].freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      SCRUBBED_HEADERS.each do |header|
        value = env[header]
        next if !value.is_a?(String) || value.valid_encoding?

        env[header] = value.scrub("")
      end

      @app.call(env)
    end
  end
end
