# frozen_string_literal: true

module FleetEvents
  # Auto-lock events as their start time approaches.
  # Honours per-event `auto_lock_enabled` and `auto_lock_minutes_before`.
  # For one-off events this transitions the event itself via AASM; for
  # recurring events it locks the next upcoming occurrence (persisted on
  # the per-occurrence state row).
  class AutoLockJob < ::ApplicationJob
    sidekiq_options retry: true, queue: "default"

    def perform
      perform_for_one_off
      perform_for_recurring
    end

    private def perform_for_one_off
      events = FleetEvent
        .where(status: "open", auto_lock_enabled: true, archived_at: nil, recurring: false)
        .where("starts_at <= NOW() + (auto_lock_minutes_before || ' minutes')::interval")

      events.find_each do |event|
        next unless event.may_lock_signups?

        event.lock_signups!
        ActiveSupport::Notifications.instrument("fleet_event.locked", event: event)
      end
    end

    private def perform_for_recurring
      now = Time.current
      events = FleetEvent
        .where(auto_lock_enabled: true, archived_at: nil, recurring: true)
        .where("status != ?", "cancelled")

      events.find_each do |event|
        window = (event.auto_lock_minutes_before || 60).minutes
        # Look slightly past the lock window so we catch occurrences whose
        # auto-lock moment is between now and now + window.
        candidates = event.occurrences(from: now - window, to: now + window)
        next if candidates.empty?

        candidates.each do |occurrence|
          lock_moment = occurrence - window
          next if now < lock_moment

          state = event.occurrence_state_for(occurrence.to_date, build: true)
          next if state.locked_at.present?
          next if state.cancelled?

          state.locked_at = now
          state.save!
          ActiveSupport::Notifications.instrument(
            "fleet_event.locked",
            event: event, occurrence_date: occurrence.to_date
          )
        end
      end
    end
  end
end
