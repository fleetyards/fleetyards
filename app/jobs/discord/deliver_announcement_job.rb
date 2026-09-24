# frozen_string_literal: true

require "discord/announcement_target"

module Discord
  class DeliverAnnouncementJob < ::ApplicationJob
    sidekiq_options retry: 3, queue: "notifications"

    # Positional on purpose: Sidekiq replays arguments positionally.
    def perform(fleet_id, kind, channel_id, content, event_id = nil)
      fleet = Fleet.find_by(id: fleet_id)
      return if fleet.blank?
      return if event_id.present? && !announceable?(event_id)

      AnnouncementTarget.new(kind, channel_id).deliver(fleet, content)
    end

    # Cancelled or archived while the post waited in the queue: sending it now
    # would announce an event that is not happening.
    private def announceable?(event_id)
      event = FleetEvent.find_by(id: event_id)

      event.present? && event.archived_at.blank? && !event.cancelled?
    end
  end
end
