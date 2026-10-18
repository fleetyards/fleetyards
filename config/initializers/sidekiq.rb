# frozen_string_literal: true

require "sidekiq/web"
require "sidekiq-scheduler/web"
require "sidekiq-failures"

sidekiq_config = {url: Rails.configuration.redis.url, db: Rails.configuration.redis.sidekiq_db}

Sidekiq.configure_server do |config|
  config.redis = sidekiq_config

  # Sidekiq logs through its own logger, not Rails.logger, so the AppSignal
  # broadcast set up in the environment config never sees worker output.
  if Appsignal.active?
    appsignal_logger = Appsignal::Logger.new("sidekiq")
    appsignal_logger.broadcast_to(config.logger)
    config.logger = appsignal_logger
  end

  # Every crop and representation decodes a whole render -- a 7694px colored
  # view peaks around 350 MB -- and a ship's import queues one per view. At the
  # worker's full concurrency they took it past its 3 GB limit and the kernel
  # killed it mid-upload, so they run in a capsule of their own. Two at a time
  # still peaked at 2.6 GB on an 8 GB host shared with Puma, so one by default;
  # a host with room to spare can raise it without a code change.
  config.capsule("preprocessing") do |capsule|
    capsule.concurrency = Integer(ENV.fetch("PREPROCESSING_CONCURRENCY", 1))
    capsule.queues = %w[preprocessing]
  end

  config.on(:startup) do
    schedule_file = Rails.root.join("config/sidekiq_schedule.yml")
    schedule_yaml = ERB.new(File.read(schedule_file)).result
    Sidekiq.schedule = YAML.safe_load(schedule_yaml, permitted_classes: [Symbol]) || {}
    SidekiqScheduler::Scheduler.instance.reload_schedule!
  end
end

Sidekiq.configure_client do |config|
  config.redis = sidekiq_config
end
