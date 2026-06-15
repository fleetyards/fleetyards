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

      request_body schema: {"$ref": "#/components/schemas/MissionUpdateInput"}, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/MissionExtended"
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
end
