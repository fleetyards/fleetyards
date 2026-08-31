# frozen_string_literal: true

require "discord/event_reminder"

module Discord
  # Posts the starting-soon reminder to a fleet's Discord webhook.
  #
  # Its own job rather than inline in the subscriber: the subscriber runs inside
  # the request or the scheduler tick that fired the notification, and a slow or
  # unreachable webhook must not hold either up.
  class AnnounceEventReminderJob < ::ApplicationJob
    sidekiq_options retry: 2, queue: "notifications"

    # Positional on purpose: Sidekiq replays arguments positionally.
    def perform(event_id, occurrence_date = nil)
      event = FleetEvent.find_by(id: event_id)
      return if event.blank?
      return if event.archived_at.present?

      EventReminder.new(
        event: event,
        occurrence_date: occurrence_date.presence && Date.parse(occurrence_date)
      ).run
    end
  end
end
