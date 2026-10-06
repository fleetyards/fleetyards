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
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, :with_squadrons, admins: [@admin], members: [@member])
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

  test "GET /fleets/:slug/squadrons/:slug tells a fleet admin they manage the roster" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug} do
      assert_equal({"manageMembers" => true, "manageRanks" => true}, parsed_body["capabilities"])
      assert_nil parsed_body["viewerRole"]
    end
  end

  test "GET /fleets/:slug/squadrons/:slug carries a plain member's squadron rank" do
    create(:fleet_squadron_membership, fleet_squadron: @squadron,
      fleet_membership: @fleet.fleet_memberships.find_by!(user: @member),
      fleet_squadron_role: @fleet.fleet_squadron_roles.find_by!(key: "officer"))
    sign_in @member

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug} do
      assert_equal "officer", parsed_body.dig("viewerRole", "key")
      assert_equal({"manageMembers" => true, "manageRanks" => false}, parsed_body["capabilities"])
    end
  end

  test "GET /fleets/:slug/squadrons/:slug tells a member whether they are in it or asked to be" do
    membership = @fleet.fleet_memberships.kept.find_by(user: @member)
    sign_in @member

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug} do
      assert_equal false, parsed_body["viewerIsMember"]
      assert_nil parsed_body["viewerRequestedAt"]
      refute parsed_body.key?("pendingRequestCount")
    end

    create(:fleet_squadron_request, fleet_squadron: @squadron, fleet_membership: membership)

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug} do
      assert parsed_body["viewerRequestedAt"].present?
    end
  end

  test "GET /fleets/:slug/squadrons/:slug counts waiting requests for whoever answers them" do
    create(:fleet_squadron_request, fleet_squadron: @squadron,
      fleet_membership: @fleet.fleet_memberships.kept.find_by(user: @member))
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug, slug: @squadron.slug} do
      assert_equal 1, parsed_body["pendingRequestCount"]
    end
  end
end
