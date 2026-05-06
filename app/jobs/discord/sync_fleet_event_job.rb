# frozen_string_literal: true

require "discord/scheduled_event_sync"

module Discord
  class SyncFleetEventJob < ::ApplicationJob
    sidekiq_options retry: 3, queue: "notifications"

    def perform(event_id, action: "upsert")
      event = FleetEvent.find_by(id: event_id)
      return unless event

      sync = Discord::ScheduledEventSync.new(event)
      return unless sync.runnable?

      case action.to_s
      when "upsert" then sync.upsert!
      when "delete" then sync.delete!
      end
    rescue Discord::ApiClient::Error => e
      Rails.logger.error("[Discord::SyncFleetEventJob] event=#{event_id} action=#{action} failed: #{e.message}")
      raise if e.status == 429 || e.status >= 500
    end
  end
end
