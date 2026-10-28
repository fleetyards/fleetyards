# frozen_string_literal: true

require "test_helper"

module Discord
  class GuildManagerCheckTest < ActiveSupport::TestCase
    GUILD = "100000000000000001"
    UID = "400000000000000001"
    MANAGERS = "200000000000000001"
    PLAIN = "200000000000000002"

    setup do
      ApiClient.stubs(:configured?).returns(true)
      @api = mock("api")
      @api.stubs(:get_guild).with(GUILD).returns({"id" => GUILD, "owner_id" => "999"})
      @api.stubs(:get_guild_roles).with(GUILD).returns([
        {"id" => GUILD, "permissions" => "0"},
        {"id" => MANAGERS, "permissions" => (GuildManagerCheck::MANAGE_GUILD | 1024).to_s},
        {"id" => PLAIN, "permissions" => "1024"}
      ])
    end

    def check(uid = UID)
      GuildManagerCheck.new(guild_id: GUILD, discord_uid: uid, api: @api)
    end

    test "the owner runs the server" do
      @api.stubs(:get_guild).with(GUILD).returns({"id" => GUILD, "owner_id" => UID})
      @api.expects(:get_guild_member).never

      assert check.manager?
    end

    test "a role with Manage Server runs it" do
      @api.stubs(:get_guild_member).with(GUILD, UID).returns({"roles" => [PLAIN, MANAGERS]})

      assert check.manager?
    end

    test "Administrator on @everyone runs it for everyone" do
      @api.stubs(:get_guild_roles).with(GUILD).returns([{"id" => GUILD, "permissions" => GuildManagerCheck::ADMINISTRATOR.to_s}])
      @api.stubs(:get_guild_member).with(GUILD, UID).returns({"roles" => []})

      assert check.manager?
    end

    test "a member without either permission does not" do
      @api.stubs(:get_guild_member).with(GUILD, UID).returns({"roles" => [PLAIN]})

      assert_not check.manager?
    end

    test "a server the bot cannot read is a no" do
      @api.stubs(:get_guild).raises(ApiClient::Error.new(403, '{"code": 50001}'))

      assert_not check.manager?
    end

    test "a user who is not on the server is a no" do
      @api.stubs(:get_guild_member).raises(ApiClient::Error.new(404, '{"code": 10007}'))

      assert_not check.manager?
    end

    test "nobody without a linked Discord account runs anything" do
      @api.expects(:get_guild).never

      assert_not check(nil).manager?
    end
  end
end
