# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsDiscordChannelsIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/discord-channels" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Fleet Discord Channels") do
      operationId "fleetDiscordChannels"
      tags "FleetNotificationSettings"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Discord::FleetDiscordChannels
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
  end

  test "GET /fleets/:slug/discord-channels lists the guild's text and announcement channels in sidebar order" do
    @fleet.create_fleet_notification_setting!(discord_guild_id: "guild-1")
    api = mock("Discord::ApiClient")
    api.stubs(:get_guild_channels).with("guild-1").returns([
      {"id" => "c2", "type" => 4, "name" => "Ops", "position" => 1},
      {"id" => "c1", "type" => 4, "name" => "General", "position" => 0},
      {"id" => "t3", "type" => 0, "name" => "mining", "position" => 0, "parent_id" => "c2"},
      {"id" => "t2", "type" => 5, "name" => "news", "position" => 1, "parent_id" => "c1"},
      {"id" => "t1", "type" => 0, "name" => "chat", "position" => 0, "parent_id" => "c1"},
      {"id" => "v1", "type" => 2, "name" => "Voice", "position" => 2, "parent_id" => "c1"},
      {"id" => "t0", "type" => 0, "name" => "rules", "position" => 0}
    ])
    Discord::ApiClient.stubs(:configured?).returns(true)
    Discord::ApiClient.stubs(:new).returns(api)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal "ok", parsed_body["code"]
      assert_equal %w[t0 t1 t2 t3], parsed_body["items"].pluck("id")
      assert_equal [nil, "General", "General", "Ops"], parsed_body["items"].pluck("parentName")
    end
  end

  test "GET /fleets/:slug/discord-channels says when no guild is bound" do
    Discord::ApiClient.stubs(:configured?).returns(true)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal "missing_guild", parsed_body["code"]
      assert_empty parsed_body["items"]
    end
  end

  test "GET /fleets/:slug/discord-channels reports a guild the bot is not in" do
    @fleet.create_fleet_notification_setting!(discord_guild_id: "guild-1")
    api = mock("Discord::ApiClient")
    api.stubs(:get_guild_channels).raises(Discord::ApiClient::Error.new(403, "missing access"))
    Discord::ApiClient.stubs(:configured?).returns(true)
    Discord::ApiClient.stubs(:new).returns(api)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal "bot_not_in_guild", parsed_body["code"]
    end
  end

  test "GET /fleets/:slug/discord-channels is open to a member who may edit squadrons" do
    Discord::ApiClient.stubs(:configured?).returns(false)
    editor = create(:user)
    role = create(:fleet_role, fleet: @fleet, name: "Wing Lead", resource_access: ["fleet:squadrons:update"])
    create(:fleet_membership, :accepted, fleet: @fleet, user: editor, fleet_role: role)
    sign_in editor

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal "missing_token", parsed_body["code"]
    end
  end

  test "GET /fleets/:slug/discord-channels returns 403 for a plain member" do
    sign_in @member

    assert_api_response :get, 403, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/discord-channels returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/discord-channels returns 404 for a fleet the user is not in" do
    sign_in create(:user)

    assert_api_response :get, 404, path_params: {fleetSlug: @fleet.slug}
  end
end
