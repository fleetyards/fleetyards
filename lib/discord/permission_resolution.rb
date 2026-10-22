# frozen_string_literal: true

require "discord/api_client"

module Discord
  # The bot's effective permissions in a guild, worked out the way Discord does:
  # its roles grant a base, and each channel's overwrites for @everyone, for its
  # roles and for the bot itself take away or add to it, in that order.
  #
  # Expects @guild_id to be set by the including class.
  module PermissionResolution
    ADMINISTRATOR = 1 << 3
    OVERWRITE_MEMBER = 1

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
  end
end
