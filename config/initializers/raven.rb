require 'raven'

Raven.configure(true) do |config|
  config.dsn = ENV.fetch('SENTRY', 'localhost')#Secrets.sentry#Rails.application.secrets.sentry
  config.environments = %w[ production ]
end
