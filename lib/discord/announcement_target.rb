# frozen_string_literal: true

require "discord/api_client"
require "discord/channel_post"
require "discord/webhook_post"

module Discord
  # One place an announcement goes, small enough to be a job's arguments. Each
  # is posted by its own job, so a retry repeats only the post that failed and
  # never one that already landed in another channel.
  #
  # The fleet's target is resolved when it is posted, not when it is queued:
  # the announcement channel if the bot can post there, the webhook otherwise
  # -- including when the channel has gone or been locked, so a fleet that set
  # up both still hears about its events.
  class AnnouncementTarget
    FLEET = "fleet"
    SQUADRON = "squadron"

    attr_reader :kind, :channel_id

    def self.fleet
      new(FLEET)
    end

    def self.squadron(channel_id)
      new(SQUADRON, channel_id)
    end

    def initialize(kind, channel_id = nil)
      @kind = kind
      @channel_id = channel_id
    end

    def to_args
      [kind, channel_id]
    end

    def ==(other)
      other.is_a?(self.class) && other.to_args == to_args
    end
    alias_method :eql?, :==

    def hash
      to_args.hash
    end

    def deliver(fleet, content)
      setting = fleet.fleet_notification_setting
      return false if setting.blank?

      case kind
      when SQUADRON then channel_post(setting, channel_id, content)
      when FLEET then fleet_post(setting, content)
      else false
      end
    end

    private def fleet_post(setting, content)
      if ApiClient.configured? && setting.discord_announcement_channel_id.present?
        return true if channel_post(setting, setting.discord_announcement_channel_id, content)
      end

      return false if setting.discord_webhook_url.blank?

      WebhookPost.new(setting.discord_webhook_url).deliver(content)
    end

    private def channel_post(setting, id, content)
      return false unless ApiClient.configured?

      ChannelPost.new(id, guild_id: setting.discord_guild_id).deliver(content)
    end
  end
end
