# frozen_string_literal: true

module Notifications
  class FleetEventStartingSoonJob < Notifications::BaseJob
    LEAD_MINUTES = 30

    def perform(window_minutes = LEAD_MINUTES)
      window = window_minutes.to_i.minutes
      now = Time.current
      cutoff = now + window

      notify_one_off(now, cutoff)
      notify_recurring(now, cutoff)
    end

    private def notify_one_off(now, cutoff)
      events = FleetEvent.where(recurring: false)
        .where(status: %w[open locked])
        .where(starting_soon_notified_at: nil)
        .where("starts_at <= ?", cutoff)
        .where("starts_at > ?", now)

      events.find_each do |event|
        ActiveSupport::Notifications.instrument("fleet_event.starting_soon", event: event)
        event.update_column(:starting_soon_notified_at, now)
      end
    end

    private def notify_recurring(now, cutoff)
      events = FleetEvent.where(recurring: true)
        .where(status: %w[open locked])

      events.find_each do |event|
        event.occurrences(from: now, to: cutoff).each do |occurrence|
          state = event.occurrence_state_for(occurrence.to_date, build: true)
          next if state.starting_soon_notified_at.present?
          next if state.cancelled?

          state.starting_soon_notified_at = now
          state.save!
          ActiveSupport::Notifications.instrument(
            "fleet_event.starting_soon",
            event: event, occurrence_date: occurrence.to_date
          )
        end
      end
    end
  end
end
