# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsCalendarSubscriptionRotateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/calendar/subscription/rotate" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}

    post("Rotate calendar subscription token") do
      operationId "rotateFleetCalendarSubscription"
      tags "Fleet Calendar"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
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

  test "POST /fleets/:slug/calendar/subscription/rotate rotates the token" do
    @fleet.ensure_calendar_feed_token!
    old_token = @fleet.reload.calendar_feed_token
    sign_in @admin

    assert_api_response :post, 200, path_params: {fleetSlug: @fleet.slug}

    new_token = @fleet.reload.calendar_feed_token
    assert new_token.present?
    refute_equal old_token, new_token
  end

  test "POST /fleets/:slug/calendar/subscription/rotate with OAuth bearer token" do
    @fleet.ensure_calendar_feed_token!

    assert_api_response :post, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"])
  end

  test "POST /fleets/:slug/calendar/subscription/rotate returns 401 for OAuth token with wrong scope" do
    assert_api_response :post, 401,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["public"])
  end

  test "POST /fleets/:slug/calendar/subscription/rotate returns 401 when not signed in" do
    assert_api_response :post, 401, path_params: {fleetSlug: @fleet.slug}
  end
end
