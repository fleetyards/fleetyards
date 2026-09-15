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

      request_body schema: ::V1::Schemas::Inputs::MissionCreateInput, required: true

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema ::V1::Schemas::Fleets::Missions::MissionExtended
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden - member cannot create") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_mission_builder")
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
      # The create button writes one of these before the author has typed
      # anything, so it must not be on the fleet's list yet.
      assert_equal "draft", parsed_body["status"]
    end
  end

  # Two clicks on the create button arrive under the same default name; the
  # second is numbered rather than refused, because the author is on their way
  # to the editor to rename it anyway.
  test "POST /fleets/:slug/missions numbers a second draft of the same name" do
    create(:mission, :draft, fleet: @fleet, created_by: @admin, title: "Untitled mission")
    sign_in @admin

    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug},
      body: {title: "Untitled mission"} do
      assert_equal "Untitled mission 2", parsed_body["title"]
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
