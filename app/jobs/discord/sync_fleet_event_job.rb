# frozen_string_literal: true

require "discord/scheduled_event_sync"

module Discord
  class SyncFleetEventJob < ::ApplicationJob
    sidekiq_options retry: 3, queue: "notifications"

    # Positional on purpose: Sidekiq serialises arguments to JSON and replays
    # them positionally, so a keyword here raises ArgumentError for every job
    # the subscriber enqueues.
    def perform(event_id, action = "upsert")
      event = FleetEvent.find_by(id: event_id)
      return unless event

      # Jobs can overtake each other: an archive enqueues a delete, and an
      # upsert queued before it would otherwise recreate the scheduled event
      # after the delete cleared its id. The event's current state decides.
      return if action.to_s == "upsert" && event.archived_at.present?

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
