# frozen_string_literal: true

require "test_helper"
require "discord/event_capability"

module Discord
  class EventCapabilityTest < ActiveSupport::TestCase
    GUILD = "900000000000000000"
    BOT = "800000000000000000"
    BOT_ROLE = "700000000000000000"
    VOICE = "600000000000000000"

    MANAGE_EVENTS = 1 << 33

    setup do
      ApiClient.stubs(:application_id).returns(BOT)
      @api = mock("Discord::ApiClient")
      @api.stubs(:get_guild_member).with(GUILD, BOT).returns({"roles" => [BOT_ROLE]})
    end

    def roles(bot_permissions)
      @api.stubs(:get_guild_roles).returns([
        {"id" => GUILD, "permissions" => (EventCapability::VIEW_CHANNEL | EventCapability::CONNECT).to_s},
        {"id" => BOT_ROLE, "permissions" => bot_permissions.to_s}
      ])
    end

    def channels(*list)
      @api.stubs(:get_guild_channels).with(GUILD).returns(list)
    end

    def check(voice_channel_id = nil)
      EventCapability.new(GUILD, api: @api).check(voice_channel_id)
    end

    test "a bot with Create Events may create an event outside any channel" do
      roles(EventCapability::CREATE_EVENTS)

      assert check.ok?
    end

    # Manage Events lets the bot edit an event, never create one.
    test "Manage Events alone is not enough" do
      roles(MANAGE_EVENTS)

      assert_equal :missing_create_events, check.code
    end

    test "Administrator covers everything" do
      roles(PermissionResolution::ADMINISTRATOR)

      assert check(VOICE).ok?
    end

    test "a voice channel the bot may see and join is ok" do
      roles(EventCapability::CREATE_EVENTS)
      channels({"id" => VOICE, "type" => EventCapability::GUILD_VOICE, "permission_overwrites" => []})

      assert check(VOICE).ok?
    end

    test "a voice channel hidden from the bot is locked" do
      roles(EventCapability::CREATE_EVENTS)
      channels({"id" => VOICE, "type" => EventCapability::GUILD_VOICE, "permission_overwrites" => [
        {"id" => GUILD, "type" => 0, "allow" => "0", "deny" => EventCapability::VIEW_CHANNEL.to_s}
      ]})

      assert_equal :voice_channel_locked, check(VOICE).code
    end

    test "a voice channel that grants Create Events itself needs no new grant" do
      roles(0)
      channels({"id" => VOICE, "type" => EventCapability::GUILD_VOICE, "permission_overwrites" => [
        {"id" => BOT, "type" => 1, "allow" => EventCapability::CREATE_EVENTS.to_s, "deny" => "0"}
      ]})

      assert check(VOICE).ok?
    end

    test "a voice channel cannot make up for a role without Create Events" do
      roles(0)
      channels({"id" => VOICE, "type" => EventCapability::GUILD_VOICE, "permission_overwrites" => []})

      assert_equal :missing_create_events, check(VOICE).code
    end

    test "a voice channel that is gone or not a voice channel is unknown" do
      roles(EventCapability::CREATE_EVENTS)
      channels({"id" => VOICE, "type" => 0, "permission_overwrites" => []})

      assert_equal :unknown_voice_channel, check(VOICE).code
      assert_equal :unknown_voice_channel, check("500000000000000000").code
    end

    test "a server the bot is not in reads as such" do
      @api.stubs(:get_guild_member).raises(ApiClient::Error.new(403, "missing access"))

      assert_equal :bot_not_in_guild, check.code
    end
  end
end
