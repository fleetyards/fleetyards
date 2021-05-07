# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq/cron/web'

sidekiq_config = { url: Rails.configuration.redis.url, db: Rails.configuration.redis.db }

Sidekiq.configure_server do |config|
  config.redis = sidekiq_config

  schedule_file = Rails.root.join('config/schedule.yml')
  schedule = YAML.load_file(schedule_file)[Rails.env] || {}
  Sidekiq::Cron::Job.load_from_hash!(schedule)
end

Sidekiq.configure_client do |config|
  config.redis = sidekiq_config
end
