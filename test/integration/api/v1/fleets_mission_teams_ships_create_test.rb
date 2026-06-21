# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsMissionTeamsShipsCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/missions/{missionSlug}/teams/{missionTeamId}/ships" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "missionSlug", in: :path, schema: {type: :string}
    parameter name: "missionTeamId", in: :path, schema: {type: :string}

    post("Create Mission Ship") do
      operationId "createMissionShip"
      tags "Missions"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/MissionShipCreateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful - range filter") do
        schema "$ref": "#/components/schemas/MissionShip"
      end

      response(400, "bad request - non-in-game model") do
        schema "$ref": "#/components/schemas/ValidationError"
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

  test "POST /fleets/:slug/missions/:slug/teams/:id/ships creates a ranged ship" do
    sign_in @admin

    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug, missionSlug: @mission.slug, missionTeamId: @team.id},
      body: {classification: "Combat", minSize: "medium"} do
      assert_equal false, parsed_body["strict"]
      assert_equal "Combat", parsed_body["filters"]["classification"]
    end
  end

  test "POST /fleets/:slug/missions/:slug/teams/:id/ships creates a specific model with materialized seats" do
    model = create(:model, in_game: true)
    positions = [
      create(:model_position, model: model, name: "Pilot", position_type: :pilot, position: 0),
      create(:model_position, model: model, name: "Co-Pilot", position_type: :copilot, position: 1)
    ]
    sign_in @admin

    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug, missionSlug: @mission.slug, missionTeamId: @team.id},
      body: {modelId: model.id, positionIds: positions.map(&:id)} do
      assert_equal true, parsed_body["strict"]
      assert_equal model.id, parsed_body["model"]["id"]
      assert_equal 2, parsed_body["slots"].size
      assert_equal ["Pilot", "Co-Pilot"].sort, parsed_body["slots"].map { |s| s["title"] }.sort
      assert parsed_body["slots"].all? { |s| s["derived"] }
    end
  end

  test "POST /fleets/:slug/missions/:slug/teams/:id/ships returns 400 for non-in-game model" do
    model = create(:model, in_game: false)
    sign_in @admin

    assert_api_response :post, 400,
      path_params: {fleetSlug: @fleet.slug, missionSlug: @mission.slug, missionTeamId: @team.id},
      body: {modelId: model.id}
  end

  test "POST /fleets/:slug/missions/:slug/teams/:id/ships with OAuth bearer token" do
    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug, missionSlug: @mission.slug, missionTeamId: @team.id},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {classification: "Combat", minSize: "medium"}
  end

  test "POST /fleets/:slug/missions/:slug/teams/:id/ships returns 401 for OAuth token with wrong scope" do
    assert_api_response :post, 401,
      path_params: {fleetSlug: @fleet.slug, missionSlug: @mission.slug, missionTeamId: @team.id},
      headers: oauth_headers_for(@admin, scopes: ["public"]),
      body: {classification: "Combat", minSize: "medium"}
  end

  test "POST /fleets/:slug/missions/:slug/teams/:id/ships returns 401 when not signed in" do
    assert_api_response :post, 401,
      path_params: {fleetSlug: @fleet.slug, missionSlug: @mission.slug, missionTeamId: @team.id},
      body: {classification: "Combat", minSize: "medium"}
  end
end
