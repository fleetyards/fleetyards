# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsInventoriesShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/inventories/{slug}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Inventory slug"

    get("Fleet Inventory Detail") do
      operationId "fleetInventory"
      tags "FleetInventories"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Fleets::Logistics::FleetInventory
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
    @inventory = create(:fleet_inventory, fleet: @fleet)
  end

  test "GET /fleets/:slug/inventories/:slug returns the inventory" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug, slug: @inventory.slug} do
      assert_equal @inventory.name, parsed_body["name"]
    end
  end

  test "GET /fleets/:slug/inventories/:slug returns 404 for unknown inventory" do
    sign_in @admin

    assert_api_response :get, 404, path_params: {fleetSlug: @fleet.slug, slug: "unknown"}
  end

  test "GET /fleets/:slug/inventories/:slug returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug, slug: @inventory.slug}
  end

  test "GET /fleets/:slug/inventories/:slug with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug, slug: @inventory.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end

  # Not found rather than forbidden: a 403 on a slug confirms the inventory
  # exists, which is most of what officers-only is hiding.
  test "GET /fleets/:slug/inventories/:slug returns 404 on an officers-only inventory for a plain member" do
    closed = create(:fleet_inventory, :officers_only, fleet: @fleet)
    sign_in @member

    assert_api_response :get, 404, path_params: {fleetSlug: @fleet.slug, slug: closed.slug}
  end

  test "GET /fleets/:slug/inventories/:slug returns an officers-only inventory to an admin" do
    closed = create(:fleet_inventory, :officers_only, fleet: @fleet)
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug, slug: closed.slug} do
      assert_equal closed.name, parsed_body["name"]
    end
  end

  test "GET /fleets/:slug/inventories/:slug returns the officers-only store its manager answers for" do
    managed = create(:fleet_inventory, :officers_only, fleet: @fleet, manager: @member)
    sign_in @member

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug, slug: managed.slug} do
      assert_equal managed.name, parsed_body["name"]
    end
  end
end
