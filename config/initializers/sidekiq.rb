# frozen_string_literal: true
require 'sidekiq/web'
require 'sidekiq-scheduler/web'

sidekiq_config = { url: ENV["REDIS_URL"] }

Sidekiq.configure_server do |config|
  config.redis = sidekiq_config
end

Sidekiq.configure_client do |config|
  config.redis = sidekiq_config
end
