# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsMissionsShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/missions/{slug}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}
    parameter name: "slug", in: :path, schema: {type: :string}

    get("Show Mission") do
      operationId "fleetMission"
      tags "Missions"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/MissionExtended"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(404, "not found") do
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

  test "GET /fleets/:slug/missions/:slug returns the mission" do
    sign_in @admin

    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug, slug: @mission.slug} do
      assert_equal @mission.title, parsed_body["title"]
      assert_kind_of Array, parsed_body["teams"]
    end
  end

  test "GET /fleets/:slug/missions/:slug returns 404 for an unknown mission" do
    sign_in @admin

    assert_api_response :get, 404,
      path_params: {fleetSlug: @fleet.slug, slug: "missing-mission"}
  end

  test "GET /fleets/:slug/missions/:slug with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug, slug: @mission.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end

  test "GET /fleets/:slug/missions/:slug returns 401 for OAuth token with wrong scope" do
    assert_api_response :get, 401,
      path_params: {fleetSlug: @fleet.slug, slug: @mission.slug},
      headers: oauth_headers_for(@admin, scopes: ["public"])
  end

  test "GET /fleets/:slug/missions/:slug returns 401 when not signed in" do
    assert_api_response :get, 401,
      path_params: {fleetSlug: @fleet.slug, slug: @mission.slug}
  end
end
