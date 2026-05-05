# frozen_string_literal: true

module Notifications
  class FleetEventStartingSoonJob < Notifications::BaseJob
    LEAD_MINUTES = 30

    def perform(window_minutes = LEAD_MINUTES)
      window = window_minutes.to_i.minutes
      cutoff = Time.current + window

      events = FleetEvent.where(status: %w[open locked])
        .where(starting_soon_notified_at: nil)
        .where("starts_at <= ?", cutoff)
        .where("starts_at > ?", Time.current)

      events.find_each do |event|
        ActiveSupport::Notifications.instrument("fleet_event.starting_soon", event: event)
        event.update_column(:starting_soon_notified_at, Time.current)
      end
    end
  end
end
