# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarInventoryStockUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/inventories/{hangarInventorySlug}/stock/{slug}" do
    parameter name: "hangarInventorySlug", in: :path, schema: {type: :string}, description: "Inventory slug"
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Stock position slug"

    patch("Update Hangar Inventory Stock Position") do
      operationId "updateHangarInventoryStockItem"
      tags "HangarInventoryStock"
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

    delete("Delete Hangar Inventory Stock Position") do
      operationId "destroyHangarInventoryStockItem"
      tags "HangarInventoryStock"

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
    @inventory = create(:hangar_inventory, user: @user)

    create(:hangar_inventory_item, hangar_inventory: @inventory,
      name: "Quantanium", category: :commodity, unit: :scu, quantity: 100)
    create(:hangar_inventory_item, :withdrawal, hangar_inventory: @inventory,
      name: "Quantanium", category: :commodity, unit: :scu, quantity: 30)

    @slug = InventoryStockItem.slug_for(name: "Quantanium", category: "commodity", unit: "scu")
  end

  test "PATCH renames every entry of the position at once" do
    sign_in @user

    assert_api_response :patch, 200,
      path_params: {hangarInventorySlug: @inventory.slug, slug: @slug},
      body: {name: "Quantanium Ore"} do
      assert_equal "Quantanium Ore", parsed_body["name"]
      assert_equal 70.0, parsed_body["netQuantity"]
      assert_equal 2, parsed_body["entriesCount"]
    end

    assert_equal 2, @inventory.hangar_inventory_items.where(name: "Quantanium Ore").count
    assert_empty @inventory.hangar_inventory_items.where(name: "Quantanium")
  end

  test "PATCH moves the position to a new category and unit together" do
    sign_in @user

    assert_api_response :patch, 200,
      path_params: {hangarInventorySlug: @inventory.slug, slug: @slug},
      body: {category: "component", unit: "units"} do
      assert_equal "component", parsed_body["category"]
      assert_equal "units", parsed_body["unit"]
      assert_equal(
        InventoryStockItem.slug_for(name: "Quantanium", category: "component", unit: "units"),
        parsed_body["slug"]
      )
    end
  end

  test "PATCH rejects a unit the new category is not measured in" do
    sign_in @user

    assert_api_response :patch, 400,
      path_params: {hangarInventorySlug: @inventory.slug, slug: @slug},
      body: {category: "component"} do
      assert_includes parsed_body["errors"].to_s, "must be units for component entries"
    end

    assert_equal ["commodity"], @inventory.hangar_inventory_items.pluck(:category).uniq
  end

  test "PATCH rejects a blank name" do
    sign_in @user

    assert_api_response :patch, 400,
      path_params: {hangarInventorySlug: @inventory.slug, slug: @slug},
      body: {name: "  "}
  end

  test "PATCH returns 404 for another user's inventory" do
    sign_in @other_user

    assert_api_response :patch, 404,
      path_params: {hangarInventorySlug: @inventory.slug, slug: @slug},
      body: {name: "Nope"}
  end

  test "PATCH returns 401 when not signed in" do
    assert_api_response :patch, 401,
      path_params: {hangarInventorySlug: @inventory.slug, slug: @slug},
      body: {name: "Nope"}
  end

  test "DELETE removes the position with all of its entries" do
    sign_in @user

    assert_difference "HangarInventoryItem.count", -2 do
      assert_api_response :delete, 204, path_params: {hangarInventorySlug: @inventory.slug, slug: @slug}
    end
  end

  test "DELETE leaves other positions alone" do
    sign_in @user

    create(:hangar_inventory_item, hangar_inventory: @inventory,
      name: "Titanium", category: :commodity, unit: :scu, quantity: 5)

    assert_api_response :delete, 204, path_params: {hangarInventorySlug: @inventory.slug, slug: @slug}

    assert_equal ["Titanium"], @inventory.hangar_inventory_items.pluck(:name)
  end

  test "DELETE returns 404 for an unknown position" do
    sign_in @user

    assert_api_response :delete, 404,
      path_params: {hangarInventorySlug: @inventory.slug, slug: "nope--commodity--scu"}
  end

  test "DELETE returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: {hangarInventorySlug: @inventory.slug, slug: @slug}
  end
end
