# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = Rails.application.credentials.sentry_dsn
  config.release = Git.revision_short
  config.traces_sample_rate = 0.2
  config.enable_logs = true
  config.enabled_patches = [:logger]

  config.before_send_log = lambda do |log|
    # Skip info logs
    return if log.level == :info

    log
  end
end

Sentry.set_tags(version: Fleetyards::VERSION)
Sentry.set_tags(codename: Fleetyards::CODENAME)
