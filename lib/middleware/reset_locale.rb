# frozen_string_literal: true

module Middleware
  # `I18n.locale` is per thread, and Puma reuses threads. The API controllers
  # assign it from `Accept-Language` for the length of their request, but nothing
  # put it back, so the next request on that thread -- an HTML page, the
  # maintenance-tasks UI, a mailer preview -- rendered in whichever language the
  # last API client asked for. An `around_action` with `I18n.with_locale` cannot
  # do this job: `rescue_from` handlers run outside the action callbacks and
  # translate their messages, so they would lose the requested locale.
  class ResetLocale
    def initialize(app)
      @app = app
    end

    def call(env)
      I18n.locale = I18n.default_locale
      @app.call(env)
    ensure
      I18n.locale = I18n.default_locale
    end
  end
end
