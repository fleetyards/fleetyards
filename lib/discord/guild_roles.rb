# frozen_string_literal: true

require "discord/guild_listing"

module Discord
  # The roles of a guild that a member can be given by hand, highest first as
  # Discord's own role list shows them. @everyone is held by every member and a
  # managed role belongs to a bot or an integration, so neither can be picked.
  class GuildRoles < GuildListing
    Role = Struct.new(:id, :name)

    private def request
      api.get_guild_roles(@guild_id)
    end

    private def pick(roles)
      roles
        .reject { |role| role["id"] == @guild_id || role["managed"] }
        .sort_by { |role| -role["position"].to_i }
        .map { |role| Role.new(id: role["id"], name: role["name"]) }
    end
  end
end
