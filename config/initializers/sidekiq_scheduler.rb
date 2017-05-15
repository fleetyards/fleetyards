# frozen_string_literal: true

if Rails.env.production?
  require 'sidekiq/scheduler'

  Sidekiq.configure_server do |config|
    config.on(:startup) do
      Sidekiq.schedule = YAML.load_file(File.expand_path('../../sidekiq_scheduler.yml', __FILE__))
      Sidekiq::Scheduler.reload_schedule!
    end
  end
end
