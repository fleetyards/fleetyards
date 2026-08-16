# frozen_string_literal: true

require "openapi_helper"

class Api::V1::VehicleInventoryItemsUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/vehicles/{vehicle_id}/inventory/items/{id}" do
    parameter name: "vehicle_id", in: :path, description: "Vehicle id or serial", schema: {type: :string}
    parameter name: "id", in: :path, schema: {type: :string}, description: "Inventory item ID"

    patch("Update Vehicle Inventory Item") do
      operationId "updateVehicleInventoryItem"
      tags "VehicleInventoryItems"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/InventoryItemUpdateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/InventoryItem"
      end

      response(400, "validation error") do
        schema "$ref": "#/components/schemas/ValidationError"
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
    Flipper.enable("ship_inventories")
    @user = create(:user)
    @other_user = create(:user)
    @vehicle = create(:vehicle, user: @user)
    @inventory = create(:inventory, holder: @user, vehicle: @vehicle)
    @item = create(:inventory_item, inventory: @inventory, name: "Quantanium", notes: nil)
  end

  test "PATCH /vehicles/:vehicle_id/inventory/items/:id renames the entry" do
    sign_in @user

    assert_api_response :patch, 200,
      path_params: {vehicle_id: @vehicle.id, id: @item.id},
      body: {name: "Quantainium", notes: "mislabelled"} do
      assert_equal "Quantainium", parsed_body["name"]
      assert_equal "mislabelled", parsed_body["notes"]
    end
  end

  test "PATCH /vehicles/:vehicle_id/inventory/items/:id rejects a blank name" do
    sign_in @user

    assert_api_response :patch, 400,
      path_params: {vehicle_id: @vehicle.id, id: @item.id},
      body: {name: ""}
  end

  test "PATCH /vehicles/:vehicle_id/inventory/items/:id returns 404 for an entry of another ship" do
    other_ship = create(:vehicle, user: @user)
    other_item = create(:inventory_item, inventory: create(:inventory, holder: @user, vehicle: other_ship))
    sign_in @user

    assert_api_response :patch, 404,
      path_params: {vehicle_id: @vehicle.id, id: other_item.id},
      body: {name: "Nope"}
  end

  test "PATCH /vehicles/:vehicle_id/inventory/items/:id returns 404 on a ship with no inventory" do
    untouched = create(:vehicle, user: @user)
    sign_in @user

    assert_api_response :patch, 404,
      path_params: {vehicle_id: untouched.id, id: @item.id},
      body: {name: "Nope"}
  end

  test "PATCH /vehicles/:vehicle_id/inventory/items/:id returns 404 for another user's ship" do
    sign_in @other_user

    assert_api_response :patch, 404,
      path_params: {vehicle_id: @vehicle.id, id: @item.id},
      body: {name: "Nope"}
  end

  test "PATCH /vehicles/:vehicle_id/inventory/items/:id returns 401 when not signed in" do
    assert_api_response :patch, 401,
      path_params: {vehicle_id: @vehicle.id, id: @item.id},
      body: {name: "Nope"}
  end

  test "PATCH /vehicles/:vehicle_id/inventory/items/:id with OAuth bearer token" do
    assert_api_response :patch, 200,
      path_params: {vehicle_id: @vehicle.id, id: @item.id},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"]),
      body: {name: "Quantainium"}
  end
end
