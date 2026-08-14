# frozen_string_literal: true

require "openapi_helper"

class Api::V1::VehicleInventoryStockUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/vehicles/{vehicle_id}/inventory/stock/{slug}" do
    parameter name: "vehicle_id", in: :path, description: "Vehicle id or serial", schema: {type: :string}
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Stock position slug"

    patch("Update Vehicle Inventory Stock Position") do
      operationId "updateVehicleInventoryStockItem"
      tags "VehicleInventoryStock"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/InventoryStockPositionInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
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

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end

    delete("Delete Vehicle Inventory Stock Position") do
      operationId "destroyVehicleInventoryStockItem"
      tags "VehicleInventoryStock"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(204, "no content")

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    Flipper.enable("hangar_inventories")
    @user = create(:user)
    @other_user = create(:user)
    @vehicle = create(:vehicle, user: @user)
    @inventory = create(:inventory, holder: @user, vehicle: @vehicle)

    create(:inventory_item, inventory: @inventory, name: "Quantanium", quantity: 100, unit: :scu)
    create(:inventory_item, :withdrawal, inventory: @inventory, name: "Quantanium", quantity: 30, unit: :scu)

    @slug = InventoryStockItem.slug_for(name: "Quantanium", category: "commodity", unit: "scu")
  end

  test "PATCH renames every entry of the position at once" do
    sign_in @user

    assert_api_response :patch, 200,
      path_params: {vehicle_id: @vehicle.id, slug: @slug},
      body: {name: "Quantainium"} do
      assert_equal "Quantainium", parsed_body["name"]
      assert_in_delta 70.0, parsed_body["netQuantity"]
    end

    assert_equal ["Quantainium"], @inventory.inventory_items.pluck(:name).uniq
  end

  test "PATCH rejects a unit the new category is not measured in" do
    sign_in @user

    assert_api_response :patch, 400,
      path_params: {vehicle_id: @vehicle.id, slug: @slug},
      body: {category: "component"}
  end

  test "PATCH returns 404 for another user's ship" do
    sign_in @other_user

    assert_api_response :patch, 404,
      path_params: {vehicle_id: @vehicle.id, slug: @slug},
      body: {name: "Nope"}
  end

  test "PATCH returns 401 when not signed in" do
    assert_api_response :patch, 401,
      path_params: {vehicle_id: @vehicle.id, slug: @slug},
      body: {name: "Nope"}
  end

  test "DELETE removes the position with all of its entries" do
    sign_in @user

    assert_difference "InventoryItem.count", -2 do
      assert_api_response :delete, 204, path_params: {vehicle_id: @vehicle.id, slug: @slug}
    end
  end

  test "DELETE leaves the inventory itself in place" do
    sign_in @user

    assert_no_difference "Inventory.count" do
      assert_api_response :delete, 204, path_params: {vehicle_id: @vehicle.id, slug: @slug}
    end
  end

  test "DELETE returns 404 for an unknown position" do
    sign_in @user

    assert_api_response :delete, 404, path_params: {vehicle_id: @vehicle.id, slug: "nope--commodity--scu"}
  end

  test "DELETE returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: {vehicle_id: @vehicle.id, slug: @slug}
  end
end
