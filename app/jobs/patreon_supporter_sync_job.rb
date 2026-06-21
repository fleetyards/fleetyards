# frozen_string_literal: true

class PatreonSupporterSyncJob < ::ApplicationJob
  sidekiq_options queue: "loaders", retry: 3

  def perform
    stats = Patreon::SupporterImporter.call
    Rails.logger.info("[PatreonSupporterSync] #{stats}")
    stats
  rescue Patreon::Error => e
    Appsignal.report_error(e)
  end
end
