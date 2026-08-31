# frozen_string_literal: true

require "test_helper"
require "discord/role_capability"

module Discord
  class RoleCapabilityTest < ActiveSupport::TestCase
    MANAGE_ROLES = ::Discord::RoleCapability::MANAGE_ROLES

    setup do
      @api = mock("Discord::ApiClient")
      ::Discord::ApiClient.stubs(:application_id).returns("bot-app-id")
    end

    def roles(*entries)
      @api.stubs(:get_guild_roles).returns(entries)
    end

    def bot_in(*role_ids)
      @api.stubs(:get_guild_member).with("guild-1", "bot-app-id").returns({"roles" => role_ids})
    end

    def role(id:, position:, permissions: 0, name: id)
      {"id" => id, "position" => position, "permissions" => permissions.to_s, "name" => name}
    end

    def check(*wanted)
      ::Discord::RoleCapability.new("guild-1", api: @api).check(wanted)
    end

    test "ok when the bot has Manage Roles and outranks the target" do
      roles(role(id: "bot", position: 10, permissions: MANAGE_ROLES), role(id: "member", position: 5))
      bot_in("bot")

      assert check("member").ok?
    end

    # Raising INSTALL_PERMISSIONS does not upgrade an existing install, so this
    # is the case that has to be reportable rather than silent.
    test "reports a missing Manage Roles permission" do
      roles(role(id: "bot", position: 10, permissions: 0), role(id: "member", position: 5))
      bot_in("bot")

      assert_equal :missing_manage_roles, check("member").code
    end

    test "administrator counts as Manage Roles" do
      roles(role(id: "bot", position: 10, permissions: ::Discord::RoleCapability::ADMINISTRATOR),
        role(id: "member", position: 5))
      bot_in("bot")

      assert check("member").ok?
    end

    test "permissions are the union of the bot's roles" do
      roles(
        role(id: "bot-a", position: 10, permissions: 0),
        role(id: "bot-b", position: 3, permissions: MANAGE_ROLES),
        role(id: "member", position: 2)
      )
      bot_in("bot-a", "bot-b")

      assert check("member").ok?
    end

    # A server-configuration problem the app cannot fix, only name.
    test "reports a target role above the bot's highest role" do
      roles(role(id: "bot", position: 5, permissions: MANAGE_ROLES),
        role(id: "member", position: 9, name: "Officers"))
      bot_in("bot")

      result = check("member")

      assert_equal :role_above_bot, result.code
      assert_includes result.detail, "Officers"
    end

    test "a role at exactly the bot's position is also out of reach" do
      roles(role(id: "bot", position: 5, permissions: MANAGE_ROLES), role(id: "member", position: 5))
      bot_in("bot")

      assert_equal :role_above_bot, check("member").code
    end

    test "reports a mapped role that no longer exists in the guild" do
      roles(role(id: "bot", position: 10, permissions: MANAGE_ROLES))
      bot_in("bot")

      result = check("deleted-role")

      assert_equal :unknown_role, result.code
      assert_includes result.detail, "deleted-role"
    end

    test "checks only the permission when nothing is mapped yet" do
      roles(role(id: "bot", position: 10, permissions: MANAGE_ROLES))
      bot_in("bot")

      assert check.ok?
    end

    test "translates a Discord error into a code" do
      @api.stubs(:get_guild_roles).raises(::Discord::ApiClient::Error.new(403, "Missing Access"))

      assert_equal :bot_not_in_guild, check("member").code
    end

    test "an invalid token is named as such" do
      @api.stubs(:get_guild_roles).raises(::Discord::ApiClient::Error.new(401, "Unauthorized"))

      assert_equal :invalid_token, check("member").code
    end
  end
end
