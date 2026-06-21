# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsEventsSignupTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/events/{slug}/signup" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "slug", in: :path, schema: {type: :string}

    post("Sign up to event without picking a slot") do
      operationId "signupFleetEvent"
      tags "Fleet Event Signups"
      consumes "application/json"
      produces "application/json"

      request_body schema: {"$ref": "#/components/schemas/FleetEventSignupCreateInput"}, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/FleetEventSignup"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    Flipper.enable("mission_builder")
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
    @fleet_event = create(:fleet_event, :open, fleet: @fleet, created_by: @admin)
  end

  test "POST /fleets/:slug/events/:slug/signup creates a signup" do
    sign_in @member

    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug},
      body: {status: "interested"} do
      assert_equal "interested", parsed_body["status"]
      assert_nil parsed_body["fleetEventSlotId"]
    end
  end

  test "POST /fleets/:slug/events/:slug/signup with OAuth bearer token" do
    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug},
      headers: oauth_headers_for(@member, scopes: ["fleet", "fleet:write"]),
      body: {status: "interested"}
  end

  test "POST /fleets/:slug/events/:slug/signup returns 401 for OAuth token with wrong scope" do
    assert_api_response :post, 401,
      path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug},
      headers: oauth_headers_for(@member, scopes: ["public"]),
      body: {status: "interested"}
  end

  test "POST /fleets/:slug/events/:slug/signup returns 401 when not signed in" do
    assert_api_response :post, 401,
      path_params: {fleetSlug: @fleet.slug, slug: @fleet_event.slug},
      body: {status: "interested"}
  end
end
