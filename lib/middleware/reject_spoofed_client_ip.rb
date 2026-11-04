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
      log_rejection(env)
      true
    end

    # This answers ahead of all request logging, so a proxy that starts sending
    # such headers would otherwise be invisible. The values are the client's.
    def log_rejection(env)
      client_ip = env["HTTP_CLIENT_IP"].to_s.truncate(100).inspect
      forwarded_for = env["HTTP_X_FORWARDED_FOR"].to_s.truncate(200).inspect

      Rails.logger.warn("rejected conflicting client address headers, Client-IP: #{client_ip}, X-Forwarded-For: #{forwarded_for}")
    end

    def bad_request
      [400, {"content-type" => "text/plain"}, ["Bad Request"]]
    end
  end
end
