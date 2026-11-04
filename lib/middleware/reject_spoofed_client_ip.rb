# frozen_string_literal: true

module Middleware
  # Scanners send a Client-IP header that disagrees with X-Forwarded-For.
  # ActionDispatch::RemoteIp only raises when the address is first read, which
  # happens deep in the app and again while logging the error page, so the
  # request ends as a 500 from the failsafe whatever the exception maps to. Read
  # it here first and answer 400. The result is memoized, so a request that passes
  # only works it out once.
  class RejectSpoofedClientIp
    def initialize(app)
      @app = app
    end

    def call(env)
      return bad_request if spoofed?(env)

      @app.call(env)
    end

    private

    def spoofed?(env)
      env["action_dispatch.remote_ip"].to_s
      false
    rescue ActionDispatch::RemoteIp::IpSpoofAttackError
      true
    end

    def bad_request
      [400, {"content-type" => "text/plain"}, ["Bad Request"]]
    end
  end
end
