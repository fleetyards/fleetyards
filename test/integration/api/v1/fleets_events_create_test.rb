# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsEventsCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/events" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}

    post("Create Fleet Event") do
      operationId "createFleetEvent"
      tags "Fleet Events"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/FleetEventCreateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/FleetEventExtended"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    Flipper.enable("mission_builder")
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
  end

  def valid_body
    {
      title: "Patrol Run",
      startsAt: 2.days.from_now.iso8601,
      timezone: "UTC",
      visibility: "members",
      autoLockEnabled: false
    }
  end

  test "POST /fleets/:slug/events creates a draft event" do
    sign_in @admin

    assert_api_response :post, 201, path_params: {fleetSlug: @fleet.slug}, body: valid_body do
      assert_equal "Patrol Run", parsed_body["title"]
      assert_equal "draft", parsed_body["status"]
    end
  end

  test "POST /fleets/:slug/events returns 403 when a member tries to create" do
    sign_in @member

    assert_api_response :post, 403, path_params: {fleetSlug: @fleet.slug}, body: valid_body
  end

  test "POST /fleets/:slug/events with OAuth bearer token" do
    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: valid_body
  end

  test "POST /fleets/:slug/events returns 401 for OAuth token with wrong scope" do
    assert_api_response :post, 401,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["public"]),
      body: valid_body
  end

  test "POST /fleets/:slug/events returns 401 when not signed in" do
    assert_api_response :post, 401, path_params: {fleetSlug: @fleet.slug}, body: valid_body
  end
end
