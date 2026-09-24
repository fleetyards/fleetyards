# frozen_string_literal: true

require "discord/api_client"
require "discord/announcement_target"

module Discord
  # Where a message about one event may be posted.
  #
  # An event held to squadrons goes to those squadrons' channels and nowhere
  # else. The fleet's channel and webhook are read by the whole fleet, so a
  # squadron without a channel of its own is simply not announced to rather than
  # announced to everybody.
  #
  # Every other event goes to the fleet's announcement channel, or through its
  # webhook when it has picked no channel -- which is all a fleet that never
  # installed the bot has.
  class EventAnnouncement
    def self.deliverable?(event)
      new(event).targets.any?
    end

    # Whether the fleet has anywhere at all to post what the whole fleet may
    # read.
    def self.fleet_targets(fleet)
      setting = fleet&.fleet_notification_setting
      return [] if setting.blank?

      channel = ApiClient.configured? &&
        setting.discord_guild_id.present? &&
        setting.discord_announcement_channel_id.present?

      (channel || setting.discord_webhook_url.present?) ? [AnnouncementTarget.fleet] : []
    end

    def self.enqueue(fleet, target, content)
      DeliverAnnouncementJob.perform_async(fleet.id, *target.to_args, content)
    end

    attr_reader :event

    def initialize(event)
      @event = event
    end

    def deliver(content)
      targets.each { |target| self.class.enqueue(event.fleet, target, content) }
    end

    def targets
      return squadron_targets if event.squadron_restricted?

      self.class.fleet_targets(event.fleet)
    end

    # Two squadrons sharing a channel would otherwise read the same message
    # twice.
    private def squadron_targets
      return [] unless ApiClient.configured?
      return [] if event.fleet&.fleet_notification_setting&.discord_guild_id.blank?

      event.fleet_squadrons.filter_map(&:discord_channel_id).uniq.map { |channel_id| AnnouncementTarget.squadron(channel_id) }
    end
  end
end
