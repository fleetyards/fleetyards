# frozen_string_literal: true

require "openapi_helper"

class Api::V1::FleetsAllInventoryItemsIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/inventory-items" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    get("Fleet All Inventory Items") do
      operationId "fleetAllInventoryItems"
      tags "FleetInventoryItems"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: FleetInventoryItem.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/FleetInventoryItemQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:read"]},
        {OpenId: ["fleet", "fleet:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/FleetInventoryItemsList"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    Flipper.enable("fleet_logistics")
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
    inventory = create(:fleet_inventory, fleet: @fleet)
    create_list(:fleet_inventory_item, 3, fleet_inventory: inventory)
  end

  test "GET /fleets/:slug/inventory-items lists all items across inventories" do
    sign_in @admin

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /fleets/:slug/inventory-items works for members" do
    sign_in @member

    assert_api_response :get, 200, path_params: {fleetSlug: @fleet.slug} do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /fleets/:slug/inventory-items returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {fleetSlug: @fleet.slug}
  end

  test "GET /fleets/:slug/inventory-items with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:read"])
  end
end
