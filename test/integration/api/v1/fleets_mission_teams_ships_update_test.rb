# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsMissionTeamsShipsUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/missions/{missionSlug}/teams/{missionTeamId}/ships/{id}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "missionSlug", in: :path, schema: {type: :string}
    parameter name: "missionTeamId", in: :path, schema: {type: :string}
    parameter name: "id", in: :path, schema: {type: :string}

    put("Update Mission Ship") do
      operationId "updateMissionShip"
      tags "Missions"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/MissionShipUpdateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/MissionShip"
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
    @ship = create(:mission_ship, :ranged, mission_team: @team)
  end

  test "PUT /fleets/:slug/missions/:slug/teams/:id/ships/:id updates the ship" do
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, missionSlug: @mission.slug, missionTeamId: @team.id, id: @ship.id},
      body: {description: "Updated description"} do
      assert_equal "Updated description", parsed_body["description"]
    end
  end

  test "PUT /fleets/:slug/missions/:slug/teams/:id/ships/:id with OAuth bearer token" do
    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, missionSlug: @mission.slug, missionTeamId: @team.id, id: @ship.id},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {description: "Updated description"}
  end

  test "PUT /fleets/:slug/missions/:slug/teams/:id/ships/:id returns 401 for OAuth token with wrong scope" do
    assert_api_response :put, 401,
      path_params: {fleetSlug: @fleet.slug, missionSlug: @mission.slug, missionTeamId: @team.id, id: @ship.id},
      headers: oauth_headers_for(@admin, scopes: ["public"]),
      body: {description: "Updated description"}
  end

  test "PUT /fleets/:slug/missions/:slug/teams/:id/ships/:id returns 401 when not signed in" do
    assert_api_response :put, 401,
      path_params: {fleetSlug: @fleet.slug, missionSlug: @mission.slug, missionTeamId: @team.id, id: @ship.id},
      body: {description: "Updated description"}
  end
end
