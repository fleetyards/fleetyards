# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsSquadronsCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/squadrons" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    post("Create Fleet Squadron") do
      operationId "createFleetSquadron"
      tags "FleetSquadrons"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::FleetSquadronCreateInput

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema ::V1::Schemas::Fleets::Squadrons::FleetSquadron
      end

      response(400, "bad request - duplicate name") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(403, "forbidden - an officer does not decide which squadrons exist") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_squadrons")
    @admin = create(:user)
    @officer = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, :with_squadrons, admins: [@admin], officers: [@officer], members: [@member])
  end

  test "POST /fleets/:slug/squadrons creates a squadron" do
    sign_in @admin

    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug},
      body: {
        name: "Combat Wing",
        shortDescription: "The pointy end",
        description: "Everything the wing does, at length.",
        color: "#FF8800"
      } do
      assert_equal "Combat Wing", parsed_body["name"]
      assert_equal "Everything the wing does, at length.", parsed_body["description"]
      assert_equal "combat-wing", parsed_body["slug"]
      assert_equal "#ff8800", parsed_body["color"]
      assert_equal 0, parsed_body["memberCount"]
    end
  end

  test "POST /fleets/:slug/squadrons returns 400 for a duplicate name" do
    create(:fleet_squadron, fleet: @fleet, name: "Combat Wing")
    sign_in @admin

    assert_api_response :post, 400, path_params: {fleetSlug: @fleet.slug}, body: {name: "combat wing"}
  end

  # Two names the uniqueness check lets through that derive one slug. Without
  # the slug validation this is the unique index raising, which reaches the
  # client as a 500.
  test "POST /fleets/:slug/squadrons returns 400 for a name colliding on the slug" do
    create(:fleet_squadron, fleet: @fleet, name: "Combat Wing")
    sign_in @admin

    assert_api_response :post, 400, path_params: {fleetSlug: @fleet.slug}, body: {name: "Combat-Wing"}
  end

  test "POST /fleets/:slug/squadrons returns 400 for a colour that is not hex" do
    sign_in @admin

    assert_api_response :post, 400, path_params: {fleetSlug: @fleet.slug}, body: {name: "Combat Wing", color: "orange"}
  end

  test "POST /fleets/:slug/squadrons allows the same name in another fleet" do
    create(:fleet_squadron, fleet: create(:fleet), name: "Combat Wing")
    sign_in @admin

    assert_api_response :post, 201, path_params: {fleetSlug: @fleet.slug}, body: {name: "Combat Wing"}
  end

  test "POST /fleets/:slug/squadrons returns 403 for an officer" do
    sign_in @officer

    assert_api_response :post, 403, path_params: {fleetSlug: @fleet.slug}, body: {name: "Officer Wing"}
  end

  test "POST /fleets/:slug/squadrons returns 403 for a plain member" do
    sign_in @member

    assert_api_response :post, 403, path_params: {fleetSlug: @fleet.slug}, body: {name: "Member Wing"}
  end

  test "POST /fleets/:slug/squadrons returns 401 when not signed in" do
    assert_api_response :post, 401, path_params: {fleetSlug: @fleet.slug}, body: {name: "Anon Wing"}
  end

  test "POST /fleets/:slug/squadrons with OAuth bearer token" do
    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {name: "OAuth Wing"}
  end
end
