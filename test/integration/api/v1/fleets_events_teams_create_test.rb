# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsEventsTeamsCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/events/{fleetEventSlug}/teams" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "fleetEventSlug", in: :path, schema: {type: :string}

    post("Create event team") do
      operationId "createFleetEventTeam"
      tags "Fleet Event Teams"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/FleetEventTeamCreateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/FleetEventTeam"
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
    @fleet_event = create(:fleet_event, fleet: @fleet, created_by: @admin)
  end

  test "POST /fleets/:slug/events/:slug/teams creates a team" do
    sign_in @admin

    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug},
      body: {title: "Strike Team", description: "Heavy fighters"} do
      assert_equal "Strike Team", parsed_body["title"]
    end
  end

  test "POST /fleets/:slug/events/:slug/teams with OAuth bearer token" do
    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {title: "Strike Team", description: "Heavy fighters"}
  end

  test "POST /fleets/:slug/events/:slug/teams returns 401 for OAuth token with wrong scope" do
    assert_api_response :post, 401,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug},
      headers: oauth_headers_for(@admin, scopes: ["public"]),
      body: {title: "Strike Team", description: "Heavy fighters"}
  end

  test "POST /fleets/:slug/events/:slug/teams returns 401 when not signed in" do
    assert_api_response :post, 401,
      path_params: {fleetSlug: @fleet.slug, fleetEventSlug: @fleet_event.slug},
      body: {title: "Strike Team", description: "Heavy fighters"}
  end
end
