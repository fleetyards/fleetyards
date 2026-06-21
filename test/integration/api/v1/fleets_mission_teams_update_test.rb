# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsMissionTeamsUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/missions/{missionSlug}/teams/{id}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "missionSlug", in: :path, schema: {type: :string}
    parameter name: "id", in: :path, schema: {type: :string}

    put("Update Mission Team") do
      operationId "updateMissionTeam"
      tags "Missions"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/MissionTeamUpdateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
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
    @team = create(:mission_team, mission: @mission)
  end

  test "PUT /fleets/:slug/missions/:slug/teams/:id updates the team" do
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, missionSlug: @mission.slug, id: @team.id},
      body: {title: "Renamed Team"} do
      assert_equal "Renamed Team", parsed_body["title"]
    end
  end

  test "PUT /fleets/:slug/missions/:slug/teams/:id with OAuth bearer token" do
    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, missionSlug: @mission.slug, id: @team.id},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {title: "Renamed Team"}
  end

  test "PUT /fleets/:slug/missions/:slug/teams/:id returns 401 for OAuth token with wrong scope" do
    assert_api_response :put, 401,
      path_params: {fleetSlug: @fleet.slug, missionSlug: @mission.slug, id: @team.id},
      headers: oauth_headers_for(@admin, scopes: ["public"]),
      body: {title: "Renamed Team"}
  end

  test "PUT /fleets/:slug/missions/:slug/teams/:id returns 401 when not signed in" do
    assert_api_response :put, 401,
      path_params: {fleetSlug: @fleet.slug, missionSlug: @mission.slug, id: @team.id},
      body: {title: "Renamed Team"}
  end
end
