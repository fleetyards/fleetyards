# frozen_string_literal: true

Raven.configure do |config|
  config.dsn = Rails.application.secrets.sentry_dsn
  config.release = Git.revision_short
  config.tags = {
    version: Fleetyards::VERSION,
    codename: Fleetyards::CODENAME
  }
end
