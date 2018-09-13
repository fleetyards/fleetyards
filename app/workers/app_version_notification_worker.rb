# frozen_string_literal: true

class AppVersionNotificationWorker
  include Sidekiq::Worker
  sidekiq_options retry: true, queue: (ENV['APP_VERSION_NOTIFICATION_QUEUE'] || 'fleetyards_app_version_notifications').to_sym

  def perform
    ActionCable.server.broadcast('app_version', {
      version: Fleetyards::VERSION,
      codename: Fleetyards::CODENAME
    }.to_json)
  end
end
