# frozen_string_literal: true

module Discord
  # Answers "can the bot actually assign these roles in this guild?" before
  # anything tries to.
  #
  # Two separate reasons it might not be able to, and a fleet can only fix one
  # of them by re-authorising:
  #
  # 1. **No Manage Roles.** Raising INSTALL_PERMISSIONS does not upgrade a
  #    server that installed the bot under the old mask -- Discord keeps the
  #    original grant. Those fleets have to re-authorise, and something has to
  #    tell them so rather than letting a job fail silently every hour.
  # 2. **Role hierarchy.** A bot can only assign roles *below* its own highest
  #    role. That is a server-configuration problem the app cannot fix, only
  #    detect and report.
  class RoleCapability
    MANAGE_ROLES = 1 << 28
    ADMINISTRATOR = 1 << 3

    Result = Struct.new(:code, :detail) do
      def ok?
        code == :ok
      end
    end

    def initialize(guild_id, api: nil)
      @guild_id = guild_id
      @api = api
    end

    # role_ids: the roles the fleet wants managed. Empty means "just tell me
    # whether the permission is there".
    def check(role_ids = [])
      wanted = Array(role_ids).compact_blank.uniq

      roles = api.get_guild_roles(@guild_id)
      return Result.new(:discord_error, "no roles returned") if roles.blank?

      own = bot_role_ids
      bot_roles = roles.select { |role| own.include?(role["id"]) }

      return Result.new(:missing_manage_roles) unless manage_roles?(bot_roles)

      unknown = wanted - roles.map { |role| role["id"] }
      return Result.new(:unknown_role, unknown.join(", ")) if unknown.any?

      above = above_bot(roles, bot_roles, wanted)
      return Result.new(:role_above_bot, above.join(", ")) if above.any?

      Result.new(:ok)
    rescue ApiClient::Error => e
      Result.new(error_code(e.status), e.message)
    end

    # The bot's own membership carries its role ids. Its user id is the
    # application id.
    private def bot_role_ids
      member = api.get_guild_member(@guild_id, ApiClient.application_id)

      Array(member&.dig("roles"))
    end

    # Permissions are a decimal string bitfield per role, and a member's
    # effective permissions are the union of their roles'. Administrator implies
    # everything, including this.
    private def manage_roles?(bot_roles)
      permissions = bot_roles.sum { |role| role["permissions"].to_i }

      permissions.anybits?(ADMINISTRATOR) || permissions.anybits?(MANAGE_ROLES)
    end

    # A role at or above the bot's highest position cannot be assigned by it,
    # even with Manage Roles.
    private def above_bot(roles, bot_roles, wanted)
      ceiling = bot_roles.map { |role| role["position"].to_i }.max || 0

      roles
        .select { |role| wanted.include?(role["id"]) && role["position"].to_i >= ceiling }
        .map { |role| role["name"] }
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
