# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsInventoriesIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/inventories" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Fleet Inventories List") do
      operationId "fleetInventories"
      tags "FleetInventories"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: 30}, required: false
      parameter name: "q", in: :query,
        schema: ::V1::Schemas::Queries::FleetInventoryQuery,
        style: :deepObject,
        explode: true,
        required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Logistics::FleetInventoriesList
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
    Flipper.enable("fleet_logistics")
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
  end

  test "GET /fleets/:slug/inventories lists inventories for admin" do
    create_list(:fleet_inventory, 3, fleet: @fleet)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /fleets/:slug/inventories lists inventories for member" do
    create_list(:fleet_inventory, 3, fleet: @fleet)
    sign_in @member

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /fleets/:slug/inventories is allowed when fleet_logistics is enabled for the fleet actor" do
    Flipper.disable("fleet_logistics")
    Flipper.enable_actor("fleet_logistics", @fleet)
    create_list(:fleet_inventory, 3, fleet: @fleet)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /fleets/:slug/inventories is allowed when fleet_logistics is enabled for the user actor" do
    Flipper.disable("fleet_logistics")
    Flipper.enable_actor("fleet_logistics", @admin)
    create_list(:fleet_inventory, 3, fleet: @fleet)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /fleets/:slug/inventories is forbidden when fleet_logistics is disabled for both user and fleet" do
    Flipper.disable("fleet_logistics")
    sign_in @admin

    get "/api/v1/fleets/#{@fleet.slug}/inventories"

    assert_response :forbidden
  end

  test "GET /fleets/:slug/inventories returns 404 for unknown fleet" do
    sign_in @admin

    assert_api_response :get, 404, path_params: {fleetSlug: "unknown-fleet"}
  end

  test "GET /fleets/:slug/inventories returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/inventories with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end

  # An officers-only store is kept from a member whose role only carries read
  # access -- its name and description included, not just its contents.
  test "GET /fleets/:slug/inventories hides an officers-only inventory from a plain member" do
    create(:fleet_inventory, fleet: @fleet, name: "Open Stores")
    create(:fleet_inventory, :officers_only, fleet: @fleet, name: "Officer Cache")
    sign_in @member

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal ["Open Stores"], parsed_body["items"].map { |entry| entry["name"] }
    end
  end

  test "GET /fleets/:slug/inventories lists an officers-only inventory for an admin" do
    create(:fleet_inventory, :officers_only, fleet: @fleet, name: "Officer Cache")
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_includes parsed_body["items"].map { |entry| entry["name"] }, "Officer Cache"
    end
  end

  test "GET /fleets/:slug/inventories lists the officers-only store its manager answers for" do
    create(:fleet_inventory, :officers_only, fleet: @fleet, name: "Officer Cache")
    create(:fleet_inventory, :officers_only, fleet: @fleet, name: "Managed Cache", manager: @member)
    sign_in @member

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal ["Managed Cache"], parsed_body["items"].map { |entry| entry["name"] }
    end
  end

  test "GET /fleets/:slug/inventories filters by visibility" do
    create(:fleet_inventory, :officers_only, fleet: @fleet, name: "Officer Cache")
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug},
      params: {q: {visibilityEq: "officers_only"}} do
      assert_equal ["Officer Cache"], parsed_body["items"].map { |entry| entry["name"] }
    end
  end

  test "GET /fleets/:slug/inventories sorts by either sort key" do
    create(:fleet_inventory, fleet: @fleet, name: "Alpha")
    create(:fleet_inventory, fleet: @fleet, name: "Zebra")
    sign_in @admin

    %i[s sorts].each do |key|
      assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug},
        params: {q: {key => "name desc"}} do
        names = parsed_body["items"].map { |entry| entry["name"] }
        assert_operator names.index("Zebra"), :<, names.index("Alpha"), key
      end
    end
  end

  # Ransack runs on top of the authorized scope, so a hand-written filter can
  # only narrow what the scope already allows. Asserted rather than read,
  # because it is the ordering of the two that makes it true.
  test "GET /fleets/:slug/inventories cannot be widened by the visibility filter" do
    create(:fleet_inventory, :officers_only, fleet: @fleet, name: "Officer Cache")
    sign_in @member

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug},
      params: {q: {visibilityEq: "officers_only"}} do
      assert_empty parsed_body["items"]
    end
  end

  test "GET inventories shows a squadron's new name after it is renamed" do
    Flipper.enable("fleet_squadrons")
    squadron = create(:fleet_squadron, fleet: @fleet, name: "Old Name")
    create(:fleet_inventory, fleet: @fleet, visibility: :squadron_only, fleet_squadrons: [squadron])
    sign_in @admin

    with_fragment_caching do
      get "/api/v1/fleets/#{@fleet.slug}/inventories"
      squadron.update!(name: "New Name")
      get "/api/v1/fleets/#{@fleet.slug}/inventories"

      assert_equal ["New Name"], response.parsed_body["items"].first["fleetSquadrons"].pluck("name")
    end
  end
end
