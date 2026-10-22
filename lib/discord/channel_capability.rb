# frozen_string_literal: true

require "discord/api_client"
require "discord/guild_channels"
require "discord/permission_resolution"

module Discord
  # Answers "can the bot post in these channels?" before an announcement finds
  # out by failing.
  #
  # Permission to post is decided per channel: the bot's roles grant a base,
  # and each channel's overwrites for @everyone, for its roles and for the bot
  # itself take away or add to it, in that order. A server that installed the
  # bot before Send Messages was requested has no base to start from at all and
  # has to re-authorise; a channel locked to a role the bot lacks is fixed in
  # the channel's own settings.
  class ChannelCapability
    include PermissionResolution

    VIEW_CHANNEL = 1 << 10
    SEND_MESSAGES = 1 << 11
    POST = VIEW_CHANNEL | SEND_MESSAGES

    Result = Struct.new(:code, :channel_ids) do
      def ok?
        code == :ok
      end
    end

    def initialize(guild_id, api: nil)
      @guild_id = guild_id
      @api = api
    end

    def check(channel_ids)
      wanted = Array(channel_ids).compact_blank.uniq
      return Result.new(:ok, []) if wanted.empty?

      channels = Array(api.get_guild_channels(@guild_id)).index_by { |channel| channel["id"] }

      # A voice channel or a category takes no messages, whatever the
      # permissions say, so it is as good as gone for an announcement.
      unknown = wanted.reject { |id| GuildChannels::POSTABLE_TYPES.include?(channels[id]&.dig("type")) }
      return Result.new(:unknown_channel, unknown) if unknown.any?

      member = api.get_guild_member(@guild_id, ApiClient.application_id)
      member_role_ids = Array(member&.dig("roles"))
      base = base_permissions(api.get_guild_roles(@guild_id), member_role_ids)

      return Result.new(:ok, []) if base.anybits?(ADMINISTRATOR)

      blocked = wanted.reject { |id| permissions_in(channels[id], base, member_role_ids).allbits?(POST) }
      return Result.new(:ok, []) if blocked.empty?

      # Re-authorising only adds Send Messages to the base. Where that alone
      # would open every blocked channel, it is the fix; a channel whose own
      # overwrites still shut the bot out needs its settings changed instead.
      locked = blocked.reject { |id| permissions_in(channels[id], base | SEND_MESSAGES, member_role_ids).allbits?(POST) }
      return Result.new(:channel_locked, locked) if locked.any?

      Result.new(:missing_send_messages, blocked)
    rescue ApiClient::Error => e
      Result.new(error_code(e.status), [])
    end

    private def api
      @api ||= ApiClient.new
    end
  end
end
