# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsDiscordRolesIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/discord-roles" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Fleet Discord Roles") do
      operationId "fleetDiscordRoles"
      tags "FleetNotificationSettings"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Discord::FleetDiscordRoles
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

  test "GET /fleets/:slug/discord-roles lists the roles a member can be given, highest first" do
    @fleet.create_fleet_notification_setting!(discord_guild_id: "100000000000000001")
    api = mock("Discord::ApiClient")
    api.stubs(:get_guild_roles).with("100000000000000001").returns([
      {"id" => "100000000000000001", "name" => "@everyone", "position" => 0},
      {"id" => "r1", "name" => "Recruit", "position" => 1},
      {"id" => "r3", "name" => "Fleetyards", "position" => 5, "managed" => true},
      {"id" => "r2", "name" => "Member", "position" => 2}
    ])
    Discord::ApiClient.stubs(:configured?).returns(true)
    Discord::ApiClient.stubs(:new).returns(api)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal "ok", parsed_body["code"]
      assert_equal %w[Member Recruit], parsed_body["items"].pluck("name")
    end
  end

  test "GET /fleets/:slug/discord-roles says when no guild is bound" do
    Discord::ApiClient.stubs(:configured?).returns(true)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal "missing_guild", parsed_body["code"]
      assert_empty parsed_body["items"]
    end
  end

  test "GET /fleets/:slug/discord-roles reports a guild the bot is not in" do
    @fleet.create_fleet_notification_setting!(discord_guild_id: "100000000000000001")
    api = mock("Discord::ApiClient")
    api.stubs(:get_guild_roles).raises(Discord::ApiClient::Error.new(403, "missing access"))
    Discord::ApiClient.stubs(:configured?).returns(true)
    Discord::ApiClient.stubs(:new).returns(api)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal "bot_not_in_guild", parsed_body["code"]
    end
  end

  test "GET /fleets/:slug/discord-roles is open to a member who may hand out invites" do
    Discord::ApiClient.stubs(:configured?).returns(false)
    recruiter = create(:user)
    role = create(:fleet_role, fleet: @fleet, name: "Recruiter", resource_access: ["fleet:invites:create"])
    create(:fleet_membership, :accepted, fleet: @fleet, user: recruiter, fleet_role: role)
    sign_in recruiter

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal "missing_token", parsed_body["code"]
    end
  end

  test "GET /fleets/:slug/discord-roles returns 403 for a plain member" do
    sign_in @member

    assert_api_response :get, 403, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/discord-roles returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/discord-roles returns 404 for a fleet the user is not in" do
    sign_in create(:user)

    assert_api_response :get, 404, path_params: {fleetSlug: @fleet.slug}
  end
end
