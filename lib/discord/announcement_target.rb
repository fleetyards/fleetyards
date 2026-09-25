# frozen_string_literal: true

require "discord/api_client"
require "discord/channel_post"
require "discord/webhook_post"

module Discord
  # One place an announcement goes, small enough to be a job's arguments. Each
  # is posted by its own job, so a retry repeats only the post that failed and
  # never one that already landed in another channel.
  #
  # The fleet's and the officers' targets are resolved when they are posted,
  # not when they are queued. The fleet's is the announcement channel if the
  # bot can post there, the webhook otherwise -- including when the channel has
  # gone or been locked, so a fleet that set up both still hears about its
  # events.
  class AnnouncementTarget
    FLEET = "fleet"
    OFFICERS = "officers"
    SQUADRON = "squadron"

    attr_reader :kind, :channel_id

    def self.fleet
      new(FLEET)
    end

    def self.officers
      new(OFFICERS)
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
      when SQUADRON then squadron_post(setting, content)
      when FLEET then fleet_post(setting, content)
      when OFFICERS then officers_post(setting, content)
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

    # Never the fleet's channel or webhook as a fallback: both are read by
    # every member.
    private def officers_post(setting, content)
      return false if setting.discord_officers_channel_id.blank?

      id = setting.discord_officers_channel_id
      return false if shared_with_fleet?(setting, id)
      return false if setting.fleet.fleet_squadrons.exists?(discord_channel_id: id)

      channel_post(setting, id, content)
    end

    # Squadrons may share a channel with each other -- both read it anyway --
    # but not with the fleet or the officers, whose readers the squadron's
    # events are kept from.
    private def squadron_post(setting, content)
      return false if shared_with_fleet?(setting, channel_id)
      return false if channel_id == setting.discord_officers_channel_id

      channel_post(setting, channel_id, content)
    end

    # A restricted audience's channel that another audience reads is refused
    # here and named on the settings page, rather than posted to.
    private def shared_with_fleet?(setting, id)
      id == setting.discord_announcement_channel_id
    end

    private def channel_post(setting, id, content)
      return false unless ApiClient.configured?

      ChannelPost.new(id, guild_id: setting.discord_guild_id).deliver(content)
    end
  end
end
