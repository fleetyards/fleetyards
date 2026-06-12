# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::FleetsInventoryItemsCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/inventories/{fleetInventorySlug}/items" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"
    parameter name: "fleetInventorySlug", in: :path, schema: {type: :string}, description: "Inventory slug"

    post("Create Fleet Inventory Item") do
      operationId "createFleetInventoryItem"
      tags "FleetInventoryItems"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/FleetInventoryItemCreateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/FleetInventoryItem"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(403, "forbidden - member cannot add items") do
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
  end

  def item_body(overrides = {})
    {name: "Quantanium", category: "commodity", quantity: 100, unit: "scu", entryType: "deposit"}.merge(overrides)
  end

  test "POST /inventories/:slug/items creates an item" do
    sign_in @admin

    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug},
      body: item_body
  end

  test "POST /inventories/:slug/items returns 403 for non-admin member" do
    sign_in @member

    assert_api_response :post, 403,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug},
      body: item_body
  end

  test "POST /inventories/:slug/items returns 401 when not signed in" do
    assert_api_response :post, 401,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug},
      body: item_body
  end

  test "POST /inventories/:slug/items with OAuth bearer token" do
    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug, fleetInventorySlug: @inventory.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: item_body
  end
end
