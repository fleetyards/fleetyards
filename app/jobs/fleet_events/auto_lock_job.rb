# frozen_string_literal: true

module FleetEvents
  # Auto-lock open events as their start time approaches.
  # Honours per-event `auto_lock_enabled` and `auto_lock_minutes_before`.
  # Locking happens via the AASM transition so the same notification
  # subscribers fire as a manual lock.
  class AutoLockJob < ::ApplicationJob
    sidekiq_options retry: true, queue: "default"

    def perform
      events = FleetEvent
        .where(status: "open", auto_lock_enabled: true, archived_at: nil)
        .where("starts_at <= NOW() + (auto_lock_minutes_before || ' minutes')::interval")

      events.find_each do |event|
        next unless event.may_lock_signups?

        event.lock_signups!
        ActiveSupport::Notifications.instrument("fleet_event.locked", event: event)
      end
    end
  end
end
