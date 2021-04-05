# frozen_string_literal: true

require 'rsi/loaner_loader'

class FleetInviteUrlCleanupWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: (ENV['FLEET_INVITE_URL_CLEANUP_QUEUE'] || 'fleetyards_fleet_invite_url_cleanup').to_sym

  def perform
    FleetInviteUrl.find_each do |invite_url|
      next unless invite_url.expired? || invite_url.limit_reached?

      invite_url.destroy
    end
  end
end
