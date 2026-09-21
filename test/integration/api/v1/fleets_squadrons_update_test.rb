# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsSquadronsUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/squadrons/{slug}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Squadron slug"

    put("Update Fleet Squadron") do
      operationId "updateFleetSquadron"
      tags "FleetSquadrons"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetSquadronUpdateInput

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Squadrons::FleetSquadron
      end

      response(400, "bad request - duplicate name") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden - an officer does not rename a squadron") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_squadrons")
    @admin = create(:user)
    @officer = create(:user)
    @fleet = create(:fleet, admins: [@admin], officers: [@officer])
    @squadron = create(:fleet_squadron, fleet: @fleet, name: "Combat Wing")
  end

  test "PUT /fleets/:slug/squadrons/:slug renames the squadron and moves its slug" do
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug},
      body: {name: "Escort Wing"} do
      assert_equal "Escort Wing", parsed_body["name"]
      assert_equal "escort-wing", parsed_body["slug"]
    end
  end

  test "PUT /fleets/:slug/squadrons/:slug updates the colour and description" do
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug},
      body: {color: "#0AF", description: "Escort duty"} do
      assert_equal "#0af", parsed_body["color"]
      assert_equal "Escort duty", parsed_body["description"]
    end
  end

  test "PUT /fleets/:slug/squadrons/:slug returns 400 for a name another squadron holds" do
    create(:fleet_squadron, fleet: @fleet, name: "Mining Division")
    sign_in @admin

    assert_api_response :put, 400,
      path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug},
      body: {name: "Mining Division"}
  end

  test "PUT /fleets/:slug/squadrons/:slug returns 403 for an officer" do
    sign_in @officer

    assert_api_response :put, 403,
      path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug},
      body: {name: "Officer Wing"}
  end

  test "PUT /fleets/:slug/squadrons/:slug returns 401 when not signed in" do
    assert_api_response :put, 401,
      path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug},
      body: {name: "Anon Wing"}
  end

  test "PUT /fleets/:slug/squadrons/:slug with OAuth bearer token" do
    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {description: "Updated by token"}
  end
end
