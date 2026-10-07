# frozen_string_literal: true

require "discord/api_client"

module Discord
  # The roles of a guild that a member can be given by hand, highest first as
  # Discord's own role list shows them. @everyone is held by every member and a
  # managed role belongs to a bot or an integration, so neither can be picked.
  class GuildRoles
    Role = Struct.new(:id, :name)

    Result = Struct.new(:code, :roles) do
      def ok?
        code == :ok
      end
    end

    def initialize(guild_id, api: nil)
      @guild_id = guild_id
      @api = api
    end

    def fetch
      return Result.new(:missing_token, []) unless ApiClient.configured?
      return Result.new(:missing_guild, []) if @guild_id.blank?

      Result.new(:ok, assignable(api.get_guild_roles(@guild_id) || []))
    rescue ApiClient::Error => e
      Result.new(error_code(e.status), [])
    end

    private def assignable(roles)
      roles
        .reject { |role| role["id"] == @guild_id || role["managed"] }
        .sort_by { |role| -role["position"].to_i }
        .map { |role| Role.new(id: role["id"], name: role["name"]) }
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
