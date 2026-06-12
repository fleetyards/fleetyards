# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::FleetsInventoriesCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/fleets/{fleetSlug}/inventories" do
    parameter name: "fleetSlug", in: :path, schema: {type: :string}, description: "Fleet slug"

    post("Create Fleet Inventory") do
      operationId "createFleetInventory"
      tags "FleetInventories"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/FleetInventoryCreateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["fleet", "fleet:write"]},
        {OpenId: ["fleet", "fleet:write"]}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/FleetInventory"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(400, "bad request - duplicate name") do
        schema "$ref": "#/components/schemas/ValidationError"
      end

      response(403, "forbidden - member cannot create") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    Flipper.enable("fleet_logistics")
    @admin = create(:user)
    @member = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@member])
  end

  test "POST /fleets/:slug/inventories creates an inventory" do
    sign_in @admin

    assert_api_response :post, 201, path_params: {fleetSlug: @fleet.slug}, body: {name: "Main Warehouse"} do
      assert_equal "Main Warehouse", parsed_body["name"]
    end
  end

  test "POST /fleets/:slug/inventories returns 400 for duplicate name" do
    create(:fleet_inventory, fleet: @fleet, name: "Main Warehouse")
    sign_in @admin

    assert_api_response :post, 400, path_params: {fleetSlug: @fleet.slug}, body: {name: "Main Warehouse"}
  end

  test "POST /fleets/:slug/inventories returns 403 for non-admin member" do
    sign_in @member

    assert_api_response :post, 403, path_params: {fleetSlug: @fleet.slug}, body: {name: "Member Warehouse"}
  end

  test "POST /fleets/:slug/inventories returns 401 when not signed in" do
    assert_api_response :post, 401, path_params: {fleetSlug: @fleet.slug}, body: {name: "x"}
  end

  test "POST /fleets/:slug/inventories with OAuth bearer token" do
    assert_api_response :post, 201,
      path_params: {fleetSlug: @fleet.slug},
      headers: oauth_headers_for(@admin, scopes: ["fleet", "fleet:write"]),
      body: {name: "OAuth Warehouse"}
  end
end
