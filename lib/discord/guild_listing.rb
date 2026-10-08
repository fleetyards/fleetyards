# frozen_string_literal: true

require "discord/api_client"

module Discord
  # Lists what a fleet's settings page picks from in its guild. A guild
  # Discord cannot list is a code for the page to explain, not an error.
  class GuildListing
    # Seconds the settings page waits on Discord.
    TIMEOUT = 5

    Result = Struct.new(:code, :items) do
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

      Result.new(:ok, pick(request || []))
    rescue ApiClient::Error => e
      Result.new(error_code(e.status), [])
    rescue Faraday::Error
      Result.new(:discord_error, [])
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
      @api ||= ApiClient.new(timeout: TIMEOUT, retries: 2)
    end
  end
end
