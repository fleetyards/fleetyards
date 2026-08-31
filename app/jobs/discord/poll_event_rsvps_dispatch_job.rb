# frozen_string_literal: true

module Discord
  # Finds the Discord scheduled events worth polling for RSVPs and fans out one
  # job per event.
  #
  # Starts from the notification settings rather than from the events: the guild
  # id lives there, every poll needs it, and a fleet without one has nothing to
  # poll.
  class PollEventRsvpsDispatchJob < ::ApplicationJob
    sidekiq_options retry: false, queue: "notifications"

    # Far enough ahead that an RSVP weeks before an event still arrives, and far
    # enough past the start that a last-minute click does too -- without polling
    # events that have been over for days.
    LOOKAHEAD = 30.days
    GRACE = 2.hours

    def perform
      return unless ApiClient.configured?

      FleetNotificationSetting.where.not(discord_guild_id: nil).includes(:fleet).find_each do |setting|
        fleet = setting.fleet
        next if fleet.blank?

        dispatch_events(setting, fleet)
        dispatch_occurrences(setting, fleet)
      end
    end

    private def dispatch_events(setting, fleet)
      fleet.fleet_events
        .where(archived_at: nil)
        .where.not(discord_event_id: nil)
        .where(starts_at: window)
        .pluck(:discord_event_id)
        .each { |event_id| enqueue(event_id, setting.discord_guild_id) }
    end

    # A recurring series pushes one Discord event per occurrence, and those ids
    # live on the occurrence state rather than on the parent row -- polling only
    # FleetEvent would miss every recurring event.
    private def dispatch_occurrences(setting, fleet)
      FleetEventOccurrenceState
        .joins(:fleet_event)
        .where(fleet_events: {fleet_id: fleet.id, archived_at: nil})
        .where.not(discord_event_id: nil)
        .where(occurrence_date: date_window)
        .pluck(:discord_event_id)
        .each { |event_id| enqueue(event_id, setting.discord_guild_id) }
    end

    private def enqueue(discord_event_id, guild_id)
      PollEventRsvpsJob.perform_async(discord_event_id, guild_id)
    end

    private def window
      (Time.current - GRACE)..(Time.current + LOOKAHEAD)
    end

    private def date_window
      Date.current..(Date.current + LOOKAHEAD)
    end
  end
end
