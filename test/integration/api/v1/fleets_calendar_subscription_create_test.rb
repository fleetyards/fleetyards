# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsCalendarSubscriptionCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/calendar/subscription" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}

    post("Generate calendar subscription token") do
      operationId "createFleetCalendarSubscription"
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

    delete("Disable calendar subscription") do
      operationId "destroyFleetCalendarSubscription"
      tags "Fleet Calendar"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
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
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
  end

  test "POST /fleets/:slug/calendar/subscription enables and returns feedUrl" do
    sign_in @admin

    assert_api_response :post, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal true, parsed_body["enabled"]
      assert_includes parsed_body["feedUrl"], "token="
    end

    assert @fleet.reload.calendar_feed_token.present?
  end

  test "POST /fleets/:slug/calendar/subscription is idempotent when already enabled" do
    @fleet.ensure_calendar_feed_token!
    existing_token = @fleet.reload.calendar_feed_token
    sign_in @admin

    assert_api_response :post, 200, path_params: {fleetSlug: @fleet.slug}

    assert_equal existing_token, @fleet.reload.calendar_feed_token
  end

  test "POST /fleets/:slug/calendar/subscription with OAuth bearer token" do
    assert_api_response :post, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"])
  end

  test "POST /fleets/:slug/calendar/subscription returns 401 for OAuth token with wrong scope" do
    assert_api_response :post, 401,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["public"])
  end

  test "POST /fleets/:slug/calendar/subscription returns 401 when not signed in" do
    assert_api_response :post, 401, path_params: {fleetSlug: @fleet.slug}
  end

  test "DELETE /fleets/:slug/calendar/subscription disables the subscription" do
    @fleet.ensure_calendar_feed_token!
    sign_in @admin

    assert_api_response :delete, 204, path_params: {fleetSlug: @fleet.slug}

    assert_nil @fleet.reload.calendar_feed_token
  end

  test "DELETE /fleets/:slug/calendar/subscription with OAuth bearer token" do
    @fleet.ensure_calendar_feed_token!

    assert_api_response :delete, 204,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"])
  end

  test "DELETE /fleets/:slug/calendar/subscription returns 401 for OAuth token with wrong scope" do
    @fleet.ensure_calendar_feed_token!

    assert_api_response :delete, 401,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["public"])
  end

  test "DELETE /fleets/:slug/calendar/subscription returns 401 when not signed in" do
    @fleet.ensure_calendar_feed_token!

    assert_api_response :delete, 401, path_params: {fleetSlug: @fleet.slug}
  end
end
