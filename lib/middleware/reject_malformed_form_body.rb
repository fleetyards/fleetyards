# frozen_string_literal: true

module Middleware
  # Rack tags a multipart field with the charset its part declares. A field
  # declared as UTF-16LE (or any other encoding that is not ASCII-compatible)
  # makes Rack's query parser raise `Encoding::CompatibilityError` when it looks
  # for brackets in the name. Rack::MethodOverride parses the form body before
  # routing and only rescues Rack's own parameter errors, so the request 500s
  # with no controller to handle it. Parse the body here first, exactly where
  # Rack::MethodOverride would, and answer 400 instead. Rack memoizes the
  # result in the env, so a well-formed body is still only parsed once.
  class RejectMalformedFormBody
    def initialize(app)
      @app = app
    end

    def call(env)
      return bad_request if incompatible_form_body?(env)

      @app.call(env)
    end

    private

    def incompatible_form_body?(env)
      return false unless env[Rack::REQUEST_METHOD] == "POST"

      request = Rack::Request.new(env)
      return false unless request.form_data? || request.parseable_data?

      request.POST
      false
    rescue Encoding::CompatibilityError
      true
    rescue
      # Everything else is Rack::MethodOverride's to report, as it would have
      # without this middleware; the error stays cached in the env for it.
      false
    end

    def bad_request
      [400, {"content-type" => "text/plain"}, ["Bad Request"]]
    end
  end
end
