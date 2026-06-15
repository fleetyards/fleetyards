# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsNotificationsDiscordStatusTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/notifications/discord-status" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}

    get("Probe the fleet's Discord guild binding") do
      operationId "fleetNotificationDiscordStatus"
      tags "Fleet Notification Settings"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema type: :object,
          properties: {
            ok: {type: :boolean},
            code: {type: :string},
            message: {type: :string},
            guildId: {type: :string},
            guildName: {type: :string},
            status: {type: :integer},
            installUrl: {type: :string}
          }
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
  end

  test "GET /fleets/:slug/notifications/discord-status returns a status payload" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/notifications/discord-status with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end

  test "GET /fleets/:slug/notifications/discord-status returns 401 for OAuth token with wrong scope" do
    assert_api_response :get, 401,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["public"])
  end

  test "GET /fleets/:slug/notifications/discord-status returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end
end
