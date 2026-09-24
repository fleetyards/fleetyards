# frozen_string_literal: true

require "discord/api_client"
require "discord/channel_post"
require "discord/webhook_post"

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

    attr_reader :event

    def initialize(event)
      @event = event
    end

    def deliver(content)
      targets.each { |target| target.deliver(content) }
    end

    def targets
      return squadron_targets if event.squadron_restricted?

      if ApiClient.configured? && setting&.discord_announcement_channel_id.present?
        [ChannelPost.new(setting.discord_announcement_channel_id)]
      elsif setting&.discord_webhook_url.present?
        [WebhookPost.new(setting.discord_webhook_url)]
      else
        []
      end
    end

    # Two squadrons sharing a channel would otherwise read the same message
    # twice.
    private def squadron_targets
      return [] unless ApiClient.configured?

      event.fleet_squadrons.filter_map(&:discord_channel_id).uniq.map { |channel_id| ChannelPost.new(channel_id) }
    end

    private def setting
      event.fleet&.fleet_notification_setting
    end
  end
end
