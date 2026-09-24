# frozen_string_literal: true

require "test_helper"
require "discord/channel_capability"

module Discord
  class ChannelCapabilityTest < ActiveSupport::TestCase
    GUILD = "900000000000000000"
    BOT = "800000000000000000"
    BOT_ROLE = "700000000000000000"
    OFFICERS = "600000000000000000"

    setup do
      ApiClient.stubs(:application_id).returns(BOT)
      @api = mock("Discord::ApiClient")
      @api.stubs(:get_guild_member).with(GUILD, BOT).returns({"roles" => [BOT_ROLE]})
    end

    def roles(bot_permissions)
      @api.stubs(:get_guild_roles).returns([
        {"id" => GUILD, "permissions" => ChannelCapability::VIEW_CHANNEL.to_s},
        {"id" => BOT_ROLE, "permissions" => bot_permissions.to_s},
        {"id" => OFFICERS, "permissions" => "0"}
      ])
    end

    def channels(*list)
      @api.stubs(:get_guild_channels).with(GUILD).returns(list)
    end

    def check(*ids)
      ChannelCapability.new(GUILD, api: @api).check(ids)
    end

    test "a channel the bot may post in is ok" do
      roles(ChannelCapability::SEND_MESSAGES)
      channels({"id" => "c1", "type" => 0, "permission_overwrites" => []})

      assert check("c1").ok?
    end

    test "an install without Send Messages has to re-authorise" do
      roles(0)
      channels({"id" => "c1", "type" => 0, "permission_overwrites" => []})

      result = check("c1")

      assert_equal :missing_send_messages, result.code
    end

    test "a channel hidden from @everyone and not reopened for the bot is locked" do
      roles(ChannelCapability::SEND_MESSAGES)
      channels(
        {"id" => "c1", "type" => 0, "permission_overwrites" => [
          {"id" => GUILD, "type" => 0, "allow" => "0", "deny" => ChannelCapability::VIEW_CHANNEL.to_s},
          {"id" => OFFICERS, "type" => 0, "allow" => ChannelCapability::VIEW_CHANNEL.to_s, "deny" => "0"}
        ]},
        {"id" => "c2", "type" => 0, "permission_overwrites" => []}
      )

      result = check("c1", "c2")

      assert_equal :channel_locked, result.code
      assert_equal ["c1"], result.channel_ids
    end

    test "an overwrite for the bot itself reopens a locked channel" do
      roles(ChannelCapability::SEND_MESSAGES)
      channels({"id" => "c1", "type" => 0, "permission_overwrites" => [
        {"id" => GUILD, "type" => 0, "allow" => "0", "deny" => ChannelCapability::VIEW_CHANNEL.to_s},
        {"id" => BOT, "type" => 1, "allow" => ChannelCapability::VIEW_CHANNEL.to_s, "deny" => "0"}
      ]})

      assert check("c1").ok?
    end

    test "a channel that no longer exists is named" do
      roles(ChannelCapability::SEND_MESSAGES)
      channels({"id" => "c1", "type" => 0, "permission_overwrites" => []})

      result = check("c1", "gone")

      assert_equal :unknown_channel, result.code
      assert_equal ["gone"], result.channel_ids
    end

    test "Administrator overrides every overwrite" do
      roles(ChannelCapability::ADMINISTRATOR)
      channels({"id" => "c1", "type" => 0, "permission_overwrites" => [
        {"id" => GUILD, "type" => 0, "allow" => "0", "deny" => ChannelCapability::POST.to_s}
      ]})

      assert check("c1").ok?
    end

    test "nothing to check is ok without asking Discord" do
      @api.expects(:get_guild_channels).never

      assert check.ok?
    end
  end
end
