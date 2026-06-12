# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::FleetsInventoryStockIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/inventories/{fleetInventorySlug}/stock" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetInventorySlug", in: :path, schema: {type: :string}, description: "Inventory slug"

    get("Fleet Inventory Stock") do
      operationId "fleetInventoryStock"
      tags "FleetInventoryStock"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/FleetInventoryStockItem"}
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    Flipper.enable("fleet_logistics")
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
    @inventory = create(:fleet_inventory, fleet: @fleet)
    create(:fleet_inventory_item, fleet_inventory: @inventory, name: "Quantanium", category: :commodity, quantity: 100, unit: :scu, entry_type: :deposit)
    create(:fleet_inventory_item, fleet_inventory: @inventory, name: "Quantanium", category: :commodity, quantity: 50, unit: :scu, entry_type: :deposit)
    create(:fleet_inventory_item, fleet_inventory: @inventory, name: "Quantanium", category: :commodity, quantity: 30, unit: :scu, entry_type: :withdrawal)
    create(:fleet_inventory_item, fleet_inventory: @inventory, name: "Medical Supplies", category: :consumable, quantity: 10, unit: :units, entry_type: :deposit)
  end

  test "GET /inventories/:slug/stock aggregates deposits minus withdrawals" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug} do
      quantanium = parsed_body.find { |d| d["name"] == "Quantanium" }
      assert_equal 120.0, quantanium["netQuantity"]
      medical = parsed_body.find { |d| d["name"] == "Medical Supplies" }
      assert_equal 10.0, medical["netQuantity"]
    end
  end

  test "GET /inventories/:slug/stock returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug}
  end

  test "GET /inventories/:slug/stock with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end
end
