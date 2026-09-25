# frozen_string_literal: true

require "discord/api_client"

module Discord
  # The channels of a guild that the bot can post an announcement to, in the
  # order Discord's own sidebar shows them: categories by position, channels by
  # position inside each, uncategorised ones first.
  class GuildChannels
    GUILD_TEXT = 0
    GUILD_CATEGORY = 4
    GUILD_ANNOUNCEMENT = 5

    POSTABLE_TYPES = [GUILD_TEXT, GUILD_ANNOUNCEMENT].freeze

    Channel = Struct.new(:id, :name, :parent_name)

    Result = Struct.new(:code, :channels) do
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

      Result.new(:ok, postable(api.get_guild_channels(@guild_id) || []))
    rescue ApiClient::Error => e
      Result.new(error_code(e.status), [])
    end

    private def postable(channels)
      categories = channels.select { |channel| channel["type"] == GUILD_CATEGORY }.index_by { |channel| channel["id"] }

      channels
        .select { |channel| POSTABLE_TYPES.include?(channel["type"]) }
        .sort_by do |channel|
          category = categories[channel["parent_id"]]
          [category ? 1 : 0, category&.dig("position").to_i, channel["position"].to_i]
        end
        .map do |channel|
          Channel.new(id: channel["id"], name: channel["name"], parent_name: categories[channel["parent_id"]]&.dig("name"))
        end
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
