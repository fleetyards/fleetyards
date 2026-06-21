# frozen_string_literal: true

class PatreonSupporterSyncJob < ::ApplicationJob
  sidekiq_options queue: "loaders", retry: 3

  def self.configured?
    Rails.application.credentials.dig(:patreon, :access_token).present? &&
      Rails.application.credentials.dig(:patreon, :campaign_id).present?
  end

  def perform
    unless self.class.configured?
      Rails.logger.info("[PatreonSupporterSync] skipped — patreon credentials not configured")
      return
    end

    stats = Patreon::SupporterImporter.call
    Rails.logger.info("[PatreonSupporterSync] #{stats}")
    stats
  rescue Patreon::Error => e
    Appsignal.report_error(e)
  end
end
