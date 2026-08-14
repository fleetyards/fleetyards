# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarInventoryStockShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/inventories/{hangarInventorySlug}/stock/{slug}" do
    parameter name: "hangarInventorySlug", in: :path, schema: {type: :string}, description: "Inventory slug"
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Stock position slug"

    get("Hangar Inventory Stock Position") do
      operationId "hangarInventoryStockItem"
      tags "HangarInventoryStock"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/InventoryStockPosition"
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
    Flipper.enable("hangar_inventories")
    @user = create(:user)
    @other_user = create(:user)
    @inventory = create(:inventory, holder: @user)

    @component = create(:component, :with_store_image, name: "FR-66 Shield Generator")

    create(:inventory_item, :component,
      inventory: @inventory, name: "FR-66 Shield Generator", quantity: 10, quality: 900)
    create(:inventory_item, :component,
      inventory: @inventory, name: "FR-66 Shield Generator", quantity: 4, quality: 500, item: @component)
    create(:inventory_item, :component, :withdrawal,
      inventory: @inventory, name: "FR-66 Shield Generator", quantity: 3, quality: 900)

    @slug = InventoryStockItem.slug_for(name: "FR-66 Shield Generator", category: "component", unit: "units")
  end

  test "GET /hangar/inventories/:slug/stock/:slug rolls up the position" do
    sign_in @user

    assert_api_response :get, 200, path_params: {hangarInventorySlug: @inventory.slug, slug: @slug} do
      assert_equal "FR-66 Shield Generator", parsed_body["name"]
      assert_equal 11.0, parsed_body["netQuantity"]
      assert_equal 3, parsed_body["entriesCount"]
      assert_equal 500, parsed_body["qualityMin"]
      assert_equal 900, parsed_body["qualityMax"]
      assert_equal @inventory.slug, parsed_body["inventory"]["slug"]
    end
  end

  test "GET /hangar/inventories/:slug/stock/:slug borrows the referenced component's image" do
    sign_in @user

    assert_api_response :get, 200, path_params: {hangarInventorySlug: @inventory.slug, slug: @slug} do
      assert_equal "Component", parsed_body["item"]["type"]
      assert_equal @component.id, parsed_body["item"]["id"]
      assert parsed_body["image"]["url"].present?
    end
  end

  test "GET /hangar/inventories/:slug/stock/:slug resolves an emptied position" do
    sign_in @user

    create(:inventory_item, inventory: @inventory, name: "Quantanium", quantity: 5, unit: :scu)
    create(:inventory_item, :withdrawal,
      inventory: @inventory, name: "Quantanium", quantity: 5, unit: :scu)

    slug = InventoryStockItem.slug_for(name: "Quantanium", category: "commodity", unit: "scu")

    assert_api_response :get, 200, path_params: {hangarInventorySlug: @inventory.slug, slug: slug} do
      assert_equal 0.0, parsed_body["netQuantity"]
      assert_equal 2, parsed_body["entriesCount"]
    end
  end

  test "GET /hangar/inventories/:slug/stock/:slug returns 404 for an unknown position" do
    sign_in @user

    assert_api_response :get, 404, path_params: {hangarInventorySlug: @inventory.slug, slug: "nope--component--units"}
  end

  test "GET /hangar/inventories/:slug/stock/:slug returns 404 for another user's inventory" do
    sign_in @other_user

    assert_api_response :get, 404, path_params: {hangarInventorySlug: @inventory.slug, slug: @slug}
  end

  test "GET /hangar/inventories/:slug/stock/:slug returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {hangarInventorySlug: @inventory.slug, slug: @slug}
  end
end
