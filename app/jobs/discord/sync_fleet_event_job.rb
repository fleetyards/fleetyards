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
      return if action.to_s.start_with?("upsert") && event.archived_at.present?
      # The same race the other way: narrowed and opened up again, the delete
      # from the narrowing can run after the upsert that restored the event.
      return if action.to_s == "delete" && event.archived_at.blank? && event.discord_guild_wide?

      sync = Discord::ScheduledEventSync.new(event)
      return unless sync.runnable?

      # A scheduled event is shown to the whole guild -- Discord has no audience
      # narrower than that -- so an event held to squadrons or to officers is
      # announced in their channels instead, and one narrowed after it was
      # posted is taken down.
      action = "delete" if action.to_s == "upsert" && !event.discord_guild_wide?
      return if action.to_s == "upsert_occurrences" && !event.discord_guild_wide?

      case action.to_s
      when "upsert" then sync.upsert!
      when "upsert_occurrences" then upsert_occurrences!(event)
      when "delete" then delete_everywhere!(event, sync)
      end
    rescue Discord::ApiClient::Error => e
      Rails.logger.error("[Discord::SyncFleetEventJob] event=#{event_id} action=#{action} failed: #{e.message}")
      raise if e.status == 429 || e.status >= 500
    end

    # Only the occurrences that already have a scheduled event: a series split
    # in two hands those to the new event, whose link and title they must now
    # carry, without announcing occurrences nobody pushed.
    private def upsert_occurrences!(event)
      event.fleet_event_occurrence_states.where.not(discord_event_id: nil).find_each do |state|
        Discord::ScheduledEventSync.new(event, occurrence_date: state.occurrence_date).upsert!
      end
    end

    # A recurring series is pushed as one scheduled event per occurrence, each
    # remembered on its occurrence state, so the series' own id is not all
    # there is to take down.
    private def delete_everywhere!(event, sync)
      sync.delete!

      event.fleet_event_occurrence_states.where.not(discord_event_id: nil).find_each do |state|
        Discord::ScheduledEventSync.new(event, occurrence_date: state.occurrence_date).delete!
      end
    end
  end
end
