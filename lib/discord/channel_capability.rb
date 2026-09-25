# frozen_string_literal: true

require "discord/api_client"
require "discord/guild_channels"

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
    ADMINISTRATOR = 1 << 3
    VIEW_CHANNEL = 1 << 10
    SEND_MESSAGES = 1 << 11
    POST = VIEW_CHANNEL | SEND_MESSAGES

    OVERWRITE_MEMBER = 1

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

    # @everyone shares the guild's id, and every member holds it implicitly.
    # Permissions are a decimal string bitfield per role; a member holds the
    # union of theirs.
    private def base_permissions(roles, member_role_ids)
      Array(roles)
        .select { |role| role["id"] == @guild_id || member_role_ids.include?(role["id"]) }
        .reduce(0) { |permissions, role| permissions | role["permissions"].to_i }
    end

    private def permissions_in(channel, base, member_role_ids)
      overwrites = Array(channel["permission_overwrites"])
      permissions = base

      everyone = overwrites.find { |overwrite| overwrite["id"] == @guild_id }
      permissions = apply(permissions, everyone["allow"].to_i, everyone["deny"].to_i) if everyone

      roles = overwrites.select { |overwrite| overwrite["type"] != OVERWRITE_MEMBER && member_role_ids.include?(overwrite["id"]) }
      permissions = apply(
        permissions,
        roles.reduce(0) { |allow, overwrite| allow | overwrite["allow"].to_i },
        roles.reduce(0) { |deny, overwrite| deny | overwrite["deny"].to_i }
      )

      own = overwrites.find { |overwrite| overwrite["type"] == OVERWRITE_MEMBER && overwrite["id"] == ApiClient.application_id }
      permissions = apply(permissions, own["allow"].to_i, own["deny"].to_i) if own

      permissions
    end

    private def apply(permissions, allow, deny)
      (permissions & ~deny) | allow
    end

    private def error_code(status)
      case status
      when 401 then :invalid_token
      when 403 then :bot_not_in_guild
      when 404 then :guild_not_found
      else :discord_error
      end
    end

    private def api
      @api ||= ApiClient.new
    end
  end
end
