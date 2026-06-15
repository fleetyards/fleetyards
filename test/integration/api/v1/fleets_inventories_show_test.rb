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
        schema "$ref": "#/components/schemas/FleetInventory"
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
    Flipper.enable("fleet_logistics")
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
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
end
