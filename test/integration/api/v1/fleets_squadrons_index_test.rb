# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsSquadronsIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/squadrons" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Fleet Squadrons List") do
      operationId "fleetSquadrons"
      tags "FleetSquadrons"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: 30}, required: false
      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::FleetSquadronQuery,
        style: :deepObject,
        explode: true,
        required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Squadrons::FleetSquadronsList
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
  end

  test "GET /fleets/:slug/squadrons lists squadrons for an admin" do
    create_list(:fleet_squadron, 3, fleet: @fleet)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /fleets/:slug/squadrons lists squadrons for a plain member" do
    create_list(:fleet_squadron, 3, fleet: @fleet)
    sign_in @member

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /fleets/:slug/squadrons counts only the accepted members of each" do
    squadron = create(:fleet_squadron, fleet: @fleet)
    accepted = create(:fleet_membership, :accepted, fleet: @fleet)
    invited = create(:fleet_membership, :invited, fleet: @fleet)
    create(:fleet_squadron_membership, fleet_squadron: squadron, fleet_membership: accepted)
    create(:fleet_squadron_membership, fleet_squadron: squadron, fleet_membership: invited)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 1, parsed_body["items"].first["memberCount"]
    end
  end

  # The detail page's text, kept off a list that never renders it.
  test "GET /fleets/:slug/squadrons leaves the full description out" do
    create(:fleet_squadron, fleet: @fleet, description: "Paragraphs and paragraphs.")
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      refute parsed_body["items"].first.key?("description")
    end
  end

  test "GET /fleets/:slug/squadrons filters by name" do
    create(:fleet_squadron, fleet: @fleet, name: "Combat Wing")
    create(:fleet_squadron, fleet: @fleet, name: "Mining Division")
    sign_in @admin

    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      params: {q: {nameCont: "Mining"}} do
      assert_equal ["Mining Division"], parsed_body["items"].map { |entry| entry["name"] }
    end
  end

  test "GET /fleets/:slug/squadrons sorts by name" do
    create(:fleet_squadron, fleet: @fleet, name: "Combat Wing")
    create(:fleet_squadron, fleet: @fleet, name: "Mining Division")
    sign_in @admin

    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      params: {q: {s: "name desc"}} do
      assert_equal ["Mining Division", "Combat Wing"], parsed_body["items"].map { |entry| entry["name"] }
    end
  end

  test "GET /fleets/:slug/squadrons shows no other fleet's squadrons" do
    create(:fleet_squadron, fleet: create(:fleet), name: "Somebody Else")
    create(:fleet_squadron, fleet: @fleet, name: "Ours")
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal ["Ours"], parsed_body["items"].map { |entry| entry["name"] }
    end
  end

  test "GET /fleets/:slug/squadrons is forbidden when fleet_squadrons is disabled" do
    Flipper.disable("fleet_squadrons")
    sign_in @admin

    get "/api/v1/fleets/#{@fleet.slug}/squadrons"

    assert_response :forbidden
  end

  test "GET /fleets/:slug/squadrons is allowed when fleet_squadrons is enabled for the fleet actor" do
    Flipper.disable("fleet_squadrons")
    Flipper.enable_actor("fleet_squadrons", @fleet)
    create(:fleet_squadron, fleet: @fleet)
    sign_in @member

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 1, parsed_body["items"].count
    end
  end

  test "GET /fleets/:slug/squadrons returns 404 for unknown fleet" do
    sign_in @admin

    assert_api_response :get, 404, path_params: {fleetSlug: "unknown-fleet"}
  end

  test "GET /fleets/:slug/squadrons returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/squadrons with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end
end
