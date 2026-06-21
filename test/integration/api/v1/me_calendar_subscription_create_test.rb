# frozen_string_literal: true

require "openapi_helper"

class Api::V1::MeCalendarSubscriptionCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/me/calendar/subscription" do
    post("Generate personal calendar subscription") do
      operationId "createMyCalendarSubscription"
      tags "Me Calendar"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user", "user:write"]},
        {OpenId: ["user", "user:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/CalendarSubscription"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    delete("Disable personal calendar subscription") do
      operationId "destroyMyCalendarSubscription"
      tags "Me Calendar"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["user", "user:write"]},
        {OpenId: ["user", "user:write"]}
      ]

      response(204, "successful") do
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

  test "POST /me/calendar/subscription enables the subscription" do
    sign_in @account

    assert_api_response :post, 200 do
      assert_equal true, parsed_body["enabled"]
      assert_includes parsed_body["feedUrl"], "token="
    end
    assert @account.reload.calendar_feed_token.present?
  end

  test "POST /me/calendar/subscription with OAuth bearer token" do
    assert_api_response :post, 200,
      headers: oauth_headers_for(@account, scopes: ["user", "user:write"])
  end

  test "POST /me/calendar/subscription returns 401 for OAuth token with wrong scope" do
    assert_api_response :post, 401,
      headers: oauth_headers_for(@account, scopes: ["public"])
  end

  test "POST /me/calendar/subscription returns 401 when not signed in" do
    assert_api_response :post, 401
  end

  test "DELETE /me/calendar/subscription disables the subscription" do
    @account.ensure_calendar_feed_token!
    sign_in @account

    assert_api_response :delete, 204

    assert_nil @account.reload.calendar_feed_token
  end

  test "DELETE /me/calendar/subscription with OAuth bearer token" do
    @account.ensure_calendar_feed_token!

    assert_api_response :delete, 204,
      headers: oauth_headers_for(@account, scopes: ["user", "user:write"])
  end

  test "DELETE /me/calendar/subscription returns 401 for OAuth token with wrong scope" do
    @account.ensure_calendar_feed_token!

    assert_api_response :delete, 401,
      headers: oauth_headers_for(@account, scopes: ["public"])
  end

  test "DELETE /me/calendar/subscription returns 401 when not signed in" do
    assert_api_response :delete, 401
  end
end
