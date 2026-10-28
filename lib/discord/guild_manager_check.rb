# frozen_string_literal: true

module Discord
  # Whether a Discord user runs a server, as the bot sees it: they own it, or
  # one of their roles carries Administrator or Manage Server. A fleet is only
  # linked to a server whose manager asks for it -- the link lets the fleet
  # answer the server's commands and hand out its roles.
  class GuildManagerCheck
    ADMINISTRATOR = 1 << 3
    MANAGE_GUILD = 1 << 5

    def initialize(guild_id:, discord_uid:, api: ApiClient.new(timeout: 5))
      @guild_id = guild_id
      @discord_uid = discord_uid
      @api = api
    end

    # Anything Discord cannot answer -- the bot is not on the server, the user
    # is not a member, the API is down -- is a no.
    def manager?
      return false if @guild_id.blank? || @discord_uid.blank? || !ApiClient.configured?

      guild = @api.get_guild(@guild_id)
      return true if guild["owner_id"].to_s == @discord_uid.to_s

      # @everyone shares the guild's id and is held without being listed.
      held = [@guild_id.to_s, *@api.get_guild_member(@guild_id, @discord_uid)["roles"].map(&:to_s)]

      @api.get_guild_roles(@guild_id).any? do |role|
        held.include?(role["id"].to_s) && (role["permissions"].to_i & (ADMINISTRATOR | MANAGE_GUILD)).positive?
      end
    rescue ApiClient::Error, Faraday::Error
      false
    end
  end
end
