# frozen_string_literal: true

require "discord/guild_listing"

module Discord
  # The channels of a guild that the bot can post an announcement to, in the
  # order Discord's own sidebar shows them: categories by position, channels by
  # position inside each, uncategorised ones first.
  class GuildChannels < GuildListing
    GUILD_TEXT = 0
    GUILD_CATEGORY = 4
    GUILD_ANNOUNCEMENT = 5

    POSTABLE_TYPES = [GUILD_TEXT, GUILD_ANNOUNCEMENT].freeze

    Channel = Struct.new(:id, :name, :parent_name)

    private def request
      api.get_guild_channels(@guild_id)
    end

    private def pick(channels)
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
  end
end
