# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsInventoryStockUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/inventories/{fleetInventorySlug}/stock/{slug}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetInventorySlug", in: :path, schema: {type: :string}, description: "Inventory slug"
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Stock position slug"

    patch("Update Fleet Inventory Stock Position") do
      operationId "updateFleetInventoryStockItem"
      tags "FleetInventoryStock"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/InventoryStockPositionInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/InventoryStockPosition"
      end

      response(400, "bad request") do
        schema "$ref": "#/components/schemas/ValidationError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    delete("Delete Fleet Inventory Stock Position") do
      operationId "destroyFleetInventoryStockItem"
      tags "FleetInventoryStock"

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(204, "no content")

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden") do
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

    create(:fleet_inventory_item, fleet_inventory: @inventory,
      name: "Quantanium", category: :commodity, unit: :scu, quantity: 100)
    create(:fleet_inventory_item, :withdrawal, fleet_inventory: @inventory,
      name: "Quantanium", category: :commodity, unit: :scu, quantity: 30)

    @slug = InventoryStockItem.slug_for(name: "Quantanium", category: "commodity", unit: "scu")
  end

  test "PATCH renames every entry of the position at once" do
    sign_in @admin

    assert_api_response :patch, 200,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug, slug: @slug},
      body: {name: "Quantanium Ore"} do
      assert_equal "Quantanium Ore", parsed_body["name"]
      assert_equal 70.0, parsed_body["netQuantity"]
    end

    assert_equal 2, @inventory.fleet_inventory_items.where(name: "Quantanium Ore").count
  end

  test "PATCH rejects a unit the new category is not measured in" do
    sign_in @admin

    assert_api_response :patch, 400,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug, slug: @slug},
      body: {category: "component"}
  end

  test "PATCH returns 401 when not signed in" do
    assert_api_response :patch, 401,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug, slug: @slug},
      body: {name: "Nope"}
  end

  test "DELETE removes the position with all of its entries" do
    sign_in @admin

    assert_difference "FleetInventoryItem.count", -2 do
      assert_api_response :delete, 204,
        path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug, slug: @slug}
    end
  end

  test "DELETE returns 404 for an unknown position" do
    sign_in @admin

    assert_api_response :delete, 404,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug, slug: "nope--commodity--scu"}
  end

  test "DELETE is refused for a member without inventory write access" do
    member = create(:user)
    create(:fleet_membership, fleet: @fleet, user: member, aasm_state: :accepted)

    sign_in member

    assert_api_response :delete, 403,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug, slug: @slug}
  end

  test "DELETE returns 401 when not signed in" do
    assert_api_response :delete, 401,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug, slug: @slug}
  end
end
