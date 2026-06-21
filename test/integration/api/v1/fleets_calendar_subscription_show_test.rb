# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsCalendarSubscriptionShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/calendar/subscription" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}

    get("Show calendar subscription") do
      operationId "fleetCalendarSubscription"
      tags "Fleet Calendar"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/CalendarSubscription"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    Flipper.enable("mission_builder")
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
  end

  test "GET /fleets/:slug/calendar/subscription returns disabled state" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal false, parsed_body["enabled"]
      assert_nil parsed_body["feedUrl"]
    end
  end

  test "GET /fleets/:slug/calendar/subscription returns enabled state with feedUrl" do
    @fleet.ensure_calendar_feed_token!
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal true, parsed_body["enabled"]
      assert_includes parsed_body["feedUrl"], "events.ics"
      assert_includes parsed_body["feedUrl"], "token="
    end
  end

  test "GET /fleets/:slug/calendar/subscription with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end

  test "GET /fleets/:slug/calendar/subscription returns 401 for OAuth token with wrong scope" do
    assert_api_response :get, 401,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["public"])
  end

  test "GET /fleets/:slug/calendar/subscription returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end
end
