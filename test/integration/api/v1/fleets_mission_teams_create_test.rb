# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsMissionTeamsCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/missions/{missionSlug}/teams" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "missionSlug", in: :path, schema: {type: :string}

    post("Create Mission Team") do
      operationId "createMissionTeam"
      tags "Missions"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/MissionTeamCreateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/MissionTeam"
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
    @mission = create(:mission, fleet: @fleet, created_by: @admin)
  end

  test "POST /fleets/:slug/missions/:slug/teams creates a team" do
    sign_in @admin

    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug, missionSlug: @mission.slug},
      body: {title: "Strike Team", description: "Main combat group"} do
      assert_equal "Strike Team", parsed_body["title"]
      assert_equal 0, parsed_body["position"]
    end
  end

  test "POST /fleets/:slug/missions/:slug/teams with OAuth bearer token" do
    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug, missionSlug: @mission.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {title: "Strike Team", description: "Main combat group"}
  end

  test "POST /fleets/:slug/missions/:slug/teams returns 401 for OAuth token with wrong scope" do
    assert_api_response :post, 401,
      path_params: {fleetSlug: @fleet.slug, missionSlug: @mission.slug},
      headers: oauth_headers_for(@admin, scopes: ["public"]),
      body: {title: "Strike Team", description: "Main combat group"}
  end

  test "POST /fleets/:slug/missions/:slug/teams returns 401 when not signed in" do
    assert_api_response :post, 401,
      path_params: {fleetSlug: @fleet.slug, missionSlug: @mission.slug},
      body: {title: "Strike Team", description: "Main combat group"}
  end
end
