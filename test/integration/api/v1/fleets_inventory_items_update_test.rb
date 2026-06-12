# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::FleetsInventoryItemsUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/inventories/{fleetInventorySlug}/items/{id}" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetInventorySlug", in: :path, schema: {type: :string}, description: "Inventory slug"
    parameter name: "id", in: :path, schema: {type: :string}, description: "Inventory item ID"

    put("Update Fleet Inventory Item") do
      operationId "updateFleetInventoryItem"
      tags "FleetInventoryItems"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/FleetInventoryItemUpdateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetInventoryItem"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden - member cannot update items") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    Flipper.enable("fleet_logistics")
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
    @inventory = create(:fleet_inventory, fleet: @fleet)
    @item = create(:fleet_inventory_item, fleet_inventory: @inventory)
  end

  test "PUT /inventories/:slug/items/:id updates the item" do
    sign_in @admin

    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug, id: @item.id},
      body: {notes: "Updated after mining run"} do
      assert_equal "Updated after mining run", parsed_body["notes"]
    end
  end

  test "PUT /inventories/:slug/items/:id returns 403 for non-admin member" do
    sign_in @member

    assert_api_response :put, 403,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug, id: @item.id},
      body: {notes: "Updated after mining run"}
  end

  test "PUT /inventories/:slug/items/:id returns 401 when not signed in" do
    assert_api_response :put, 401,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug, id: @item.id},
      body: {notes: "Updated after mining run"}
  end

  test "PUT /inventories/:slug/items/:id with OAuth bearer token" do
    assert_api_response :put, 200,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug, id: @item.id},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {notes: "OAuth updated note"}
  end
end
