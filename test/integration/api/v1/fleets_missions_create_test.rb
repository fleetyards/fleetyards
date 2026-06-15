# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsMissionsCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/missions" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}

    post("Create Mission") do
      operationId "createFleetMission"
      tags "Missions"
      consumes "application/json"
      produces "application/json"

      request_body schema: {"$ref": "#/components/schemas/MissionCreateInput"}, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/MissionExtended"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden - member cannot create") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    Flipper.enable("mission_builder")
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
  end

  test "POST /fleets/:slug/missions creates a mission" do
    sign_in @admin

    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug},
      body: {title: "Operation Bluebird", description: "Cargo run"} do
      assert_equal "Operation Bluebird", parsed_body["title"]
      assert_equal "operation-bluebird", parsed_body["slug"]
    end
  end

  test "POST /fleets/:slug/missions returns 403 when caller is a member" do
    sign_in @member

    assert_api_response :post, 403,
      path_params: {fleetSlug: @fleet.slug},
      body: {title: "Operation Bluebird", description: "Cargo run"}
  end

  test "POST /fleets/:slug/missions with OAuth bearer token" do
    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {title: "Operation Bluebird", description: "Cargo run"}
  end

  test "POST /fleets/:slug/missions returns 401 for OAuth token with wrong scope" do
    assert_api_response :post, 401,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["public"]),
      body: {title: "Operation Bluebird", description: "Cargo run"}
  end

  test "POST /fleets/:slug/missions returns 401 when not signed in" do
    assert_api_response :post, 401,
      path_params: {fleetSlug: @fleet.slug},
      body: {title: "Operation Bluebird", description: "Cargo run"}
  end
end
