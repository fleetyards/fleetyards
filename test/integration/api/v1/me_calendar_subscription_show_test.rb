# frozen_string_literal: true

require "openapi_helper"

class Api::V1::MeCalendarSubscriptionShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/me/calendar/subscription" do
    get("Show personal calendar subscription") do
      operationId "myCalendarSubscription"
      tags "Me Calendar"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user", "user:read"]},
        {OpenId: ["user", "user:read"]}
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
    @account = create(:user)
  end

  test "GET /me/calendar/subscription returns disabled when no token is set" do
    sign_in @account

    assert_api_response :get, 200 do
      assert_equal false, parsed_body["enabled"]
      assert_nil parsed_body["feedUrl"]
    end
  end

  test "GET /me/calendar/subscription returns enabled when a token is set" do
    @account.ensure_calendar_feed_token!
    sign_in @account

    assert_api_response :get, 200 do
      assert_equal true, parsed_body["enabled"]
      assert_includes parsed_body["feedUrl"], "/me/calendar/events.ics"
      assert_includes parsed_body["feedUrl"], "token="
    end
  end

  test "GET /me/calendar/subscription with OAuth bearer token" do
    assert_api_response :get, 200,
      headers: oauth_headers_for(@account, scopes: ["user", "user:read"])
  end

  test "GET /me/calendar/subscription returns 401 for OAuth token with wrong scope" do
    assert_api_response :get, 401,
      headers: oauth_headers_for(@account, scopes: ["public"])
  end

  test "GET /me/calendar/subscription returns 401 when not signed in" do
    assert_api_response :get, 401
  end
end
