# frozen_string_literal: true

require "test_helper"

module Discord
  class GuildListingTest < ActiveSupport::TestCase
    GUILD = "100000000000000001"

    setup do
      ApiClient.stubs(:configured?).returns(true)
      @api = mock("Discord::ApiClient")
    end

    test "a guild Discord does not answer for in time reads as a Discord error" do
      @api.stubs(:get_guild_roles).raises(Faraday::TimeoutError)

      result = GuildRoles.new(GUILD, api: @api).fetch

      assert_equal :discord_error, result.code
      assert_empty result.items
    end

    test "a dropped connection reads as a Discord error" do
      @api.stubs(:get_guild_channels).raises(Faraday::ConnectionFailed.new("reset"))

      assert_equal :discord_error, GuildChannels.new(GUILD, api: @api).fetch.code
    end
  end
end
