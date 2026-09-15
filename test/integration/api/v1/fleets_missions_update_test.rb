# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsMissionsUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/missions/{slug}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "slug", in: :path, schema: {type: :string}

    put("Update Mission") do
      operationId "updateFleetMission"
      tags "Missions"
      consumes "application/json"
      produces "application/json"

      request_body schema: ::V1::Schemas::Inputs::MissionUpdateInput, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Missions::MissionExtended
      end

      response(400, "bad request") do
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

  test "PUT /fleets/:slug/missions/:slug updates the mission" do
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, slug: @mission.slug},
      body: {title: "Updated Mission"} do
      assert_equal "Updated Mission", parsed_body["title"]
    end
  end

  test "PUT /fleets/:slug/missions/:slug with OAuth bearer token" do
    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, slug: @mission.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {title: "Updated Mission"}
  end

  test "PUT /fleets/:slug/missions/:slug returns 401 for OAuth token with wrong scope" do
    assert_api_response :put, 401,
      path_params: {fleetSlug: @fleet.slug, slug: @mission.slug},
      headers: oauth_headers_for(@admin, scopes: ["public"]),
      body: {title: "Updated Mission"}
  end

  test "PUT /fleets/:slug/missions/:slug returns 401 when not signed in" do
    assert_api_response :put, 401,
      path_params: {fleetSlug: @fleet.slug, slug: @mission.slug},
      body: {title: "Updated Mission"}
  end
  # Only the provisional title a draft arrives with is renamed. One somebody
  # typed is theirs alone, and the editor says so rather than quietly numbering
  # it behind them.
  test "PATCH /fleets/:slug/missions/:slug refuses a title another mission holds" do
    create(:mission, fleet: @fleet, created_by: @admin, title: "Operation Bluebird")
    sign_in @admin

    assert_api_response :put, 400,
      path_params: {fleetSlug: @fleet.slug, slug: @mission.slug},
      body: {title: "Operation Bluebird"}
  end
end
