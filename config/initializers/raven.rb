require 'raven'

Raven.configure(true) do |config|
  config.dsn = Secrets.sentry#Rails.application.secrets.sentry
  config.environments = %w[ production ]
end
