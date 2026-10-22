# frozen_string_literal: true

require "discord/api_client"
require "discord/permission_resolution"

module Discord
  # Answers "can the bot push the fleet's events to Discord as scheduled
  # events?" before a sync finds out by failing.
  #
  # Creating one needs Create Events; Manage Events only covers editing and
  # deleting, so a server can let the bot keep an existing event up to date and
  # still refuse every new one. An event placed in a voice channel is checked
  # against the bot's permissions in that channel, which also need View Channel
  # and Connect. A server that installed the bot before Create Events was
  # requested can grant it to the bot's role or re-authorise; a voice channel
  # that shuts the bot out is fixed in the channel's own settings.
  class EventCapability
    include PermissionResolution

    VIEW_CHANNEL = 1 << 10
    CONNECT = 1 << 20
    CREATE_EVENTS = 1 << 44
    VOICE_EVENT = CREATE_EVENTS | VIEW_CHANNEL | CONNECT

    GUILD_VOICE = 2

    Result = Struct.new(:code) do
      def ok?
        code == :ok
      end
    end

    def initialize(guild_id, api: nil)
      @guild_id = guild_id
      @api = api
    end

    def check(voice_channel_id = nil)
      member = api.get_guild_member(@guild_id, ApiClient.application_id)
      member_role_ids = Array(member&.dig("roles"))
      base = base_permissions(api.get_guild_roles(@guild_id), member_role_ids)

      return Result.new(:ok) if base.anybits?(ADMINISTRATOR)

      if voice_channel_id.blank?
        return Result.new(base.anybits?(CREATE_EVENTS) ? :ok : :missing_create_events)
      end

      channel = Array(api.get_guild_channels(@guild_id)).find { |candidate| candidate["id"] == voice_channel_id }
      return Result.new(:unknown_voice_channel) unless channel&.dig("type") == GUILD_VOICE

      permissions = permissions_in(channel, base, member_role_ids)
      return Result.new(:ok) if permissions.allbits?(VOICE_EVENT)
      # Missing at the guild level as well is the role's to fix; missing only
      # here is the channel's.
      return Result.new(:missing_create_events) unless base.anybits?(CREATE_EVENTS) || permissions.anybits?(CREATE_EVENTS)

      Result.new(:voice_channel_locked)
    rescue ApiClient::Error => e
      Result.new(error_code(e.status))
    end

    private def api
      @api ||= ApiClient.new
    end
  end
end
