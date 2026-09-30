# frozen_string_literal: true

module Middleware
  # The public file server marks everything under public/ immutable for a year,
  # which suits fingerprinted assets and not the service worker: its URL never
  # changes. Browsers revalidate the worker script themselves, but a cache in
  # between that honours the header would hold an old worker -- and with it an
  # old push handler -- for as long as it likes.
  class ServiceWorkerCacheControl
    PATHS = %w[/sw.js /sw.js.map].freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)
      headers["cache-control"] = "no-cache" if PATHS.include?(env["PATH_INFO"])

      [status, headers, body]
    end
  end
end
