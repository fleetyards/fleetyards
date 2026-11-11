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

      request_body required: true, schema: ::V1::Schemas::Inputs::MissionTeamCreateInput

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema ::V1::Schemas::Fleets::Missions::MissionTeam
      end

      response(400, "validation error") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_mission_builder")
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

  test "POST /fleets/:slug/missions/:slug/teams from a squadron takes its name and description" do
    squadron = create(:fleet_squadron, fleet: @fleet, name: "Alpha Wing", short_description: "Interceptors")
    sign_in @admin

    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug, missionSlug: @mission.slug},
      body: {title: "", fleetSquadronId: squadron.id} do
      assert_equal "Alpha Wing", parsed_body["title"]
      assert_equal "Interceptors", parsed_body["description"]
      assert_equal squadron.id, parsed_body.dig("fleetSquadron", "id")
    end
  end

  test "POST /fleets/:slug/missions/:slug/teams refuses another fleet's squadron" do
    foreign = create(:fleet_squadron)
    sign_in @admin

    assert_api_response :post, 400,
      path_params: {fleetSlug: @fleet.slug, missionSlug: @mission.slug},
      body: {title: "Strike Team", fleetSquadronId: foreign.id}
  end

  test "refuses a squadron id that names no squadron" do
    sign_in @admin

    assert_api_response :post, 400,
      path_params: {fleetSlug: @fleet.slug, missionSlug: @mission.slug},
      body: {title: "Strike Team", fleetSquadronId: SecureRandom.uuid}
  end
end
