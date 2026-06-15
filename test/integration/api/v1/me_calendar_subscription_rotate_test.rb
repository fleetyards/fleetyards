# frozen_string_literal: true

require "openapi_helper"

class Api::V1::MeCalendarSubscriptionRotateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/me/calendar/subscription/rotate" do
    post("Rotate personal calendar subscription") do
      operationId "rotateMyCalendarSubscription"
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
  end

  setup do
    Flipper.enable("mission_builder")
    @account = create(:user)
  end

  test "POST /me/calendar/subscription/rotate rotates the token" do
    @account.ensure_calendar_feed_token!
    old_token = @account.reload.calendar_feed_token
    sign_in @account

    assert_api_response :post, 200

    new_token = @account.reload.calendar_feed_token
    assert new_token.present?
    refute_equal old_token, new_token
  end

  test "POST /me/calendar/subscription/rotate with OAuth bearer token" do
    @account.ensure_calendar_feed_token!

    assert_api_response :post, 200,
      headers: oauth_headers_for(@account, scopes: ["user", "user:write"])
  end

  test "POST /me/calendar/subscription/rotate returns 401 for OAuth token with wrong scope" do
    assert_api_response :post, 401,
      headers: oauth_headers_for(@account, scopes: ["public"])
  end

  test "POST /me/calendar/subscription/rotate returns 401 when not signed in" do
    assert_api_response :post, 401
  end
end
