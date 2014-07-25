require 'raven'

Raven.configure(true) do |config|
  config.dsn = ENV['SENTRY']#Secrets.sentry#Rails.application.secrets.sentry
  config.environments = %w[ production ]
end
