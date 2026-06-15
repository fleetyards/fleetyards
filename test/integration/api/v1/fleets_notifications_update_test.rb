# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsNotificationsUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/notifications" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}

    patch("Update fleet notification settings") do
      operationId "updateFleetNotificationSetting"
      tags "Fleet Notification Settings"
      consumes "application/json"
      produces "application/json"

      request_body schema: {
        type: :object,
        properties: {
          discordGuildId: {type: :string},
          discordChannelId: {type: :string},
          discordWebhookUrl: {type: :string},
          enabledInAppEvents: {type: :array, items: {type: :string}}
        }
      }, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetNotificationSetting"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
    @request_body = {
      discordGuildId: "123456789012345678",
      discordChannelId: "234567890123456789",
      enabledInAppEvents: ["fleet_event.published"]
    }
  end

  test "PATCH /fleets/:slug/notifications updates the settings" do
    sign_in @admin

    assert_api_response :patch, 200,
      path_params: {fleetSlug: @fleet.slug},
      body: @request_body do
      assert_equal "123456789012345678", parsed_body["discordGuildId"]
      assert_includes parsed_body["enabledInAppEvents"], "fleet_event.published"
    end
  end

  test "PATCH /fleets/:slug/notifications with OAuth bearer token" do
    assert_api_response :patch, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: @request_body
  end

  test "PATCH /fleets/:slug/notifications returns 401 for OAuth token with wrong scope" do
    assert_api_response :patch, 401,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["public"]),
      body: @request_body
  end

  test "PATCH /fleets/:slug/notifications returns 401 when not signed in" do
    assert_api_response :patch, 401,
      path_params: {fleetSlug: @fleet.slug},
      body: @request_body
  end
end
