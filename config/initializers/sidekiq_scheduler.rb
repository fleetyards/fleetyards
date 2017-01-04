require 'sidekiq/scheduler'

if Rails.env.production?
  Sidekiq.configure_server do |config|

    config.on(:startup) do
      Sidekiq.schedule = YAML.load_file(File.expand_path('../../sidekiq_scheduler.yml', __FILE__))
    end
  end
else
  Sidekiq::Scheduler.enabled = false
end
