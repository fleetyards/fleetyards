# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsSquadronsShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/squadrons/{slug}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Squadron slug"

    get("Fleet Squadron") do
      operationId "fleetSquadron"
      tags "FleetSquadrons"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Squadrons::FleetSquadron
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("fleet_squadrons")
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
    @squadron = create(:fleet_squadron, :with_color, fleet: @fleet, name: "Combat Wing",
      short_description: "The pointy end", description: "Everything the wing does, at length.")
  end

  test "GET /fleets/:slug/squadrons/:slug returns the squadron" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug} do
      assert_equal "Combat Wing", parsed_body["name"]
      assert_equal "combat-wing", parsed_body["slug"]
      assert_equal "The pointy end", parsed_body["shortDescription"]
      assert_equal "Everything the wing does, at length.", parsed_body["description"]
      assert_equal "#ff8800", parsed_body["color"]
      assert_equal 0, parsed_body["memberCount"]
    end
  end

  test "GET /fleets/:slug/squadrons/:slug is readable by a plain member" do
    sign_in @member

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug}
  end

  # The lookup runs through the authorized scope, so a role with no squadron
  # access is told the squadron does not exist rather than that it may not
  # read it.
  test "GET /fleets/:slug/squadrons/:slug returns 404 for a role with no squadron access" do
    role = create(:fleet_role, fleet: @fleet, name: "Recruit", resource_access: [])
    recruit = create(:user)
    create(:fleet_membership, :accepted, fleet: @fleet, user: recruit, fleet_role: role)
    sign_in recruit

    assert_api_response :get, 404, path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug}
  end

  test "GET /fleets/:slug/squadrons/:slug returns 404 for a squadron of another fleet" do
    other = create(:fleet_squadron, fleet: create(:fleet))
    sign_in @admin

    assert_api_response :get, 404, path_params: {fleetSlug: @fleet.slug, slug: other.slug}
  end

  test "GET /fleets/:slug/squadrons/:slug returns 404 for an unknown squadron" do
    sign_in @admin

    assert_api_response :get, 404, path_params: {fleetSlug: @fleet.slug, slug: "no-such-wing"}
  end

  test "GET /fleets/:slug/squadrons/:slug returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug}
  end

  test "GET /fleets/:slug/squadrons/:slug with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end
end
