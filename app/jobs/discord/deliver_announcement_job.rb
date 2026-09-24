# frozen_string_literal: true

require "discord/announcement_target"
require "discord/event_announcement"

module Discord
  class DeliverAnnouncementJob < ::ApplicationJob
    sidekiq_options retry: 3, queue: "notifications"

    # Positional on purpose: Sidekiq replays arguments positionally.
    def perform(fleet_id, kind, channel_id, content, event_id = nil)
      fleet = Fleet.find_by(id: fleet_id)
      return if fleet.blank?
      target = AnnouncementTarget.new(kind, channel_id)
      return if event_id.present? && !announceable?(event_id, target)

      target.deliver(fleet, content)
    end

    # Cancelled or archived while the post waited in the queue, sending it now
    # would announce an event that is not happening; narrowed meanwhile, it
    # would announce it to people it is now kept from.
    private def announceable?(event_id, target)
      event = FleetEvent.find_by(id: event_id)
      return false if event.blank? || event.archived_at.present? || event.cancelled?

      EventAnnouncement.new(event).targets.include?(target)
    end
  end
end
