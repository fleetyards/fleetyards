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
end
