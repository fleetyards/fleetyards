# frozen_string_literal: true

require "openapi_helper"

class Api::V1::VehicleInventoryItemsDestroyTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/vehicles/{vehicle_id}/inventory/items/{id}" do
    parameter name: "vehicle_id", in: :path, description: "Vehicle id or serial", schema: {type: :string}
    parameter name: "id", in: :path, schema: {type: :string}, description: "Inventory item ID"

    delete("Delete Vehicle Inventory Item") do
      operationId "destroyVehicleInventoryItem"
      tags "VehicleInventoryItems"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(204, "successful")

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("ship_inventories")
    @user = create(:user)
    @other_user = create(:user)
    @vehicle = create(:vehicle, user: @user)
    @inventory = create(:inventory, holder: @user, vehicle: @vehicle)
    @item = create(:inventory_item, inventory: @inventory)
  end

  test "DELETE /vehicles/:vehicle_id/inventory/items/:id deletes the entry" do
    sign_in @user

    assert_difference "InventoryItem.count", -1 do
      assert_api_response :delete, 204, path_params: {vehicle_id: @vehicle.id, id: @item.id}
    end
  end

  test "DELETE /vehicles/:vehicle_id/inventory/items/:id keeps the inventory" do
    sign_in @user

    assert_no_difference "Inventory.count" do
      assert_api_response :delete, 204, path_params: {vehicle_id: @vehicle.id, id: @item.id}
    end
  end

  test "DELETE /vehicles/:vehicle_id/inventory/items/:id returns 404 on a ship with no inventory" do
    untouched = create(:vehicle, user: @user)
    sign_in @user

    assert_api_response :delete, 404, path_params: {vehicle_id: untouched.id, id: @item.id}
  end

  test "DELETE /vehicles/:vehicle_id/inventory/items/:id returns 404 for another user's ship" do
    sign_in @other_user

    assert_no_difference "InventoryItem.count" do
      assert_api_response :delete, 404, path_params: {vehicle_id: @vehicle.id, id: @item.id}
    end
  end

  test "DELETE /vehicles/:vehicle_id/inventory/items/:id returns 401 when not signed in" do
    assert_no_difference "InventoryItem.count" do
      assert_api_response :delete, 401, path_params: {vehicle_id: @vehicle.id, id: @item.id}
    end
  end

  test "DELETE /vehicles/:vehicle_id/inventory/items/:id with OAuth bearer token" do
    assert_difference "InventoryItem.count", -1 do
      assert_api_response :delete, 204,
        path_params: {vehicle_id: @vehicle.id, id: @item.id},
        headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"])
    end
  end
end
