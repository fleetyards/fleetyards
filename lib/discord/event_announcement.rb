# frozen_string_literal: true

require "discord/api_client"
require "discord/announcement_target"

module Discord
  # Where a message about one event may be posted.
  #
  # An event held to squadrons goes to those squadrons' channels and nowhere
  # else, and one kept to officers goes to the officers' channel. The fleet's
  # channel and webhook are read by the whole fleet, so without a channel of
  # their own those events are simply not announced rather than announced to
  # everybody.
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

    def self.officers_targets(fleet)
      setting = fleet&.fleet_notification_setting
      return [] unless ApiClient.configured?
      return [] if setting&.discord_guild_id.blank? || setting.discord_officers_channel_id.blank?

      [AnnouncementTarget.officers]
    end

    def self.enqueue(fleet, target, content, event_id: nil)
      DeliverAnnouncementJob.perform_async(fleet.id, *target.to_args, content, event_id)
    end

    attr_reader :event

    def initialize(event)
      @event = event
    end

    def deliver(content)
      targets.each { |target| self.class.enqueue(event.fleet, target, content, event_id: event.id) }
    end

    def targets
      return squadron_targets if event.squadron_restricted?
      return self.class.officers_targets(event.fleet) if event.officers_only?

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
