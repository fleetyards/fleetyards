# frozen_string_literal: true

require "sidekiq/web"
require "sidekiq-scheduler/web"
require "sidekiq-failures"

sidekiq_config = {url: Rails.configuration.redis.url, db: Rails.configuration.redis.db}

Sidekiq.configure_server do |config|
  config.redis = sidekiq_config

  config.on(:startup) do
    schedule_file = Rails.root.join("config/sidekiq_schedule.yml")
    Sidekiq.schedule = YAML.load_file(schedule_file, aliases: true)[Rails.env] || {}
    SidekiqScheduler::Scheduler.instance.reload_schedule!
  end
end

Sidekiq.configure_client do |config|
  config.redis = sidekiq_config
end
