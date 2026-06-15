# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsMissionTeamsShipsSortTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/missions/{missionSlug}/teams/{missionTeamId}/ships/sort" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "missionSlug", in: :path, schema: {type: :string}
    parameter name: "missionTeamId", in: :path, schema: {type: :string}

    put("Sort Mission Ships") do
      operationId "sortMissionShips"
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
    @team = create(:mission_team, mission: @mission)
    @ships = create_list(:mission_ship, 3, :ranged, mission_team: @team)
  end

  test "PUT /fleets/:slug/missions/:slug/teams/:id/ships/sort updates positions" do
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, missionSlug: @mission.slug, missionTeamId: @team.id},
      body: {sorting: @ships.reverse.map(&:id)}

    @ships.reverse.each_with_index do |ship, index|
      assert_equal index, ship.reload.position
    end
  end

  test "PUT /fleets/:slug/missions/:slug/teams/:id/ships/sort with OAuth bearer token" do
    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, missionSlug: @mission.slug, missionTeamId: @team.id},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {sorting: @ships.reverse.map(&:id)}
  end

  test "PUT /fleets/:slug/missions/:slug/teams/:id/ships/sort returns 401 for OAuth token with wrong scope" do
    assert_api_response :put, 401,
      path_params: {fleetSlug: @fleet.slug, missionSlug: @mission.slug, missionTeamId: @team.id},
      headers: oauth_headers_for(@admin, scopes: ["public"]),
      body: {sorting: @ships.reverse.map(&:id)}
  end

  test "PUT /fleets/:slug/missions/:slug/teams/:id/ships/sort returns 401 when not signed in" do
    assert_api_response :put, 401,
      path_params: {fleetSlug: @fleet.slug, missionSlug: @mission.slug, missionTeamId: @team.id},
      body: {sorting: @ships.reverse.map(&:id)}
  end
end
