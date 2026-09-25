# frozen_string_literal: true

require "discord/announcement_target"
require "discord/event_announcement"
require "discord/weekly_digest"

module Discord
  class DeliverAnnouncementJob < ::ApplicationJob
    sidekiq_options retry: 3, queue: "notifications"

    # Positional on purpose: Sidekiq replays arguments positionally.
    def perform(fleet_id, kind, channel_id, content, event_id = nil, digest = false)
      fleet = Fleet.kept.find_by(id: fleet_id)
      return if fleet.blank?
      target = AnnouncementTarget.new(kind, channel_id)

      if digest
        setting = fleet.fleet_notification_setting
        # Switched off while its posts waited in the queue.
        return unless setting&.digest_enabled?
        # Waited past its week, overtaken by a later claim, or rescheduled
        # meanwhile: the digest it belonged to is not the one due any more.
        return if digest.is_a?(String) && !setting.digest_claim_live?(Time.iso8601(digest))

        content = WeeklyDigest.new(fleet).content_for_target(target)
        return if content.blank?
      elsif event_id.present?
        return unless announceable?(event_id, target)
      end

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
