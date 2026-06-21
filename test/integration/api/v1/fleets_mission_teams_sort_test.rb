# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsMissionTeamsSortTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/missions/{missionSlug}/teams/sort" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "missionSlug", in: :path, schema: {type: :string}

    put("Sort Mission Teams") do
      operationId "sortMissionTeams"
      tags "Missions"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/SortInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema type: :object, properties: {success: {type: :boolean}}
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
    @teams = create_list(:mission_team, 3, mission: @mission)
  end

  test "PUT /fleets/:slug/missions/:slug/teams/sort updates positions" do
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, missionSlug: @mission.slug},
      body: {sorting: @teams.reverse.map(&:id)}

    @teams.reverse.each_with_index do |team, index|
      assert_equal index, team.reload.position
    end
  end

  test "PUT /fleets/:slug/missions/:slug/teams/sort with OAuth bearer token" do
    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, missionSlug: @mission.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {sorting: @teams.reverse.map(&:id)}
  end

  test "PUT /fleets/:slug/missions/:slug/teams/sort returns 401 for OAuth token with wrong scope" do
    assert_api_response :put, 401,
      path_params: {fleetSlug: @fleet.slug, missionSlug: @mission.slug},
      headers: oauth_headers_for(@admin, scopes: ["public"]),
      body: {sorting: @teams.reverse.map(&:id)}
  end

  test "PUT /fleets/:slug/missions/:slug/teams/sort returns 401 when not signed in" do
    assert_api_response :put, 401,
      path_params: {fleetSlug: @fleet.slug, missionSlug: @mission.slug},
      body: {sorting: @teams.reverse.map(&:id)}
  end
end
