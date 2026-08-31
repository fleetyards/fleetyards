# frozen_string_literal: true

require "test_helper"

class Api::V1::FleetsNotificationsDiscordStatusBehaviourTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
    @url = "/api/v1/fleets/#{@fleet.slug}/notifications/discord-status"
    sign_in @admin
  end

  test "reports missing_token when the bot token isn't configured" do
    Discord::ApiClient.stubs(:configured?).returns(false)

    get @url, as: :json

    assert_response :ok
    body = JSON.parse(response.body)
    assert_equal false, body["ok"]
    assert_equal "missing_token", body["code"]
  end

  test "reports missing_guild when no guild id is set" do
    Discord::ApiClient.stubs(:configured?).returns(true)

    get @url, as: :json

    body = JSON.parse(response.body)
    assert_equal false, body["ok"]
    assert_equal "missing_guild", body["code"]
  end

  test "reports ok and the guild name on success" do
    @fleet.create_fleet_notification_setting!(discord_guild_id: "guild-1")
    api = mock("Discord::ApiClient")
    api.stubs(:get_guild).returns({"id" => "guild-1", "name" => "Test Server"})
    Discord::ApiClient.stubs(:configured?).returns(true)
    Discord::ApiClient.stubs(:new).returns(api)

    get @url, as: :json

    body = JSON.parse(response.body)
    assert_equal true, body["ok"]
    assert_equal "Test Server", body["guildName"]
  end

  test "reports bot_not_in_guild on a 403" do
    @fleet.create_fleet_notification_setting!(discord_guild_id: "guild-1")
    api = mock("Discord::ApiClient")
    api.stubs(:get_guild).raises(Discord::ApiClient::Error.new(403, "missing access"))
    Discord::ApiClient.stubs(:configured?).returns(true)
    Discord::ApiClient.stubs(:new).returns(api)

    get @url, as: :json

    body = JSON.parse(response.body)
    assert_equal false, body["ok"]
    assert_equal "bot_not_in_guild", body["code"]
  end

  test "reports guild_not_found on a 404" do
    @fleet.create_fleet_notification_setting!(discord_guild_id: "guild-1")
    api = mock("Discord::ApiClient")
    api.stubs(:get_guild).raises(Discord::ApiClient::Error.new(404, "unknown guild"))
    Discord::ApiClient.stubs(:configured?).returns(true)
    Discord::ApiClient.stubs(:new).returns(api)

    get @url, as: :json

    body = JSON.parse(response.body)
    assert_equal "guild_not_found", body["code"]
  end

  test "reports invalid_token on a 401" do
    @fleet.create_fleet_notification_setting!(discord_guild_id: "guild-1")
    api = mock("Discord::ApiClient")
    api.stubs(:get_guild).raises(Discord::ApiClient::Error.new(401, "unauthorized"))
    Discord::ApiClient.stubs(:configured?).returns(true)
    Discord::ApiClient.stubs(:new).returns(api)

    get @url, as: :json

    body = JSON.parse(response.body)
    assert_equal "invalid_token", body["code"]
  end

  test "includes installUrl when the bot client_id is configured" do
    Discord::ApiClient.stubs(:configured?).returns(true)
    Discord::ApiClient.stubs(:application_id).returns("123456789")

    get @url, as: :json

    body = JSON.parse(response.body)
    assert body["installUrl"].start_with?("https://discord.com/oauth2/authorize?client_id=123456789")
    assert_includes body["installUrl"], "scope=bot+applications.commands"
  end

  test "omits installUrl when the bot client_id is not configured" do
    Discord::ApiClient.stubs(:configured?).returns(true)
    Discord::ApiClient.stubs(:application_id).returns(nil)

    get @url, as: :json

    body = JSON.parse(response.body)
    assert_nil body["installUrl"]
  end

  class RoleCapabilityTest < Api::V1::FleetsNotificationsDiscordStatusBehaviourTest
    setup do
      @api = mock("Discord::ApiClient")
      @api.stubs(:get_guild).returns({"id" => "guild-1", "name" => "Test Server"})
      Discord::ApiClient.stubs(:configured?).returns(true)
      Discord::ApiClient.stubs(:new).returns(@api)
    end

    def map_member_role!
      @fleet.create_fleet_notification_setting!(
        discord_guild_id: "guild-1",
        discord_member_role_id: "role-member"
      )
    end

    def body
      get @url, as: :json
      JSON.parse(response.body)
    end

    # A fleet that never mapped a role is not told to re-authorise for a
    # feature it is not using.
    test "says nothing about roles when the fleet mapped none" do
      @fleet.create_fleet_notification_setting!(discord_guild_id: "guild-1")

      payload = body

      assert_equal true, payload["ok"]
      assert_nil payload["rolesOk"]
      assert_nil payload["rolesCode"]
    end

    test "reports role management as ok once it works" do
      map_member_role!
      capability = mock
      capability.stubs(:check).returns(Discord::RoleCapability::Result.new(:ok))
      Discord::RoleCapability.stubs(:new).returns(capability)

      payload = body

      assert_equal true, payload["rolesOk"]
      assert_equal "ok", payload["rolesCode"]
    end

    # The point of the whole thing: an install from before Manage Roles was
    # requested keeps its old grant, and Discord never upgrades it.
    test "tells a fleet installed under the old mask that roles do not work" do
      map_member_role!
      capability = mock
      capability.stubs(:check).returns(Discord::RoleCapability::Result.new(:missing_manage_roles))
      Discord::RoleCapability.stubs(:new).returns(capability)

      payload = body

      assert_equal false, payload["rolesOk"]
      assert_equal "missing_manage_roles", payload["rolesCode"]
    end

    test "passes the offending role name through for a hierarchy problem" do
      map_member_role!
      capability = mock
      capability.stubs(:check).returns(Discord::RoleCapability::Result.new(:role_above_bot, "Officers"))
      Discord::RoleCapability.stubs(:new).returns(capability)

      payload = body

      assert_equal "role_above_bot", payload["rolesCode"]
      assert_equal "Officers", payload["rolesDetail"]
    end

    test "the install url now asks for Manage Roles" do
      Discord::ApiClient.stubs(:application_id).returns("123456789")

      assert_includes body["installUrl"], "permissions=#{Discord::ApiClient::INSTALL_PERMISSIONS}"
    end
  end
end
