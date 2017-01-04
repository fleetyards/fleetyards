if Rails.env.production?
  require 'sidekiq/scheduler'

  Sidekiq.configure_server do |config|
    config.on(:startup) do
      Sidekiq.schedule = YAML.load_file(File.expand_path('../../sidekiq_scheduler.yml', __FILE__))
      Sidekiq::Scheduler.dynamic = true
    end
  end
end
