# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarInventoryStockIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/inventories/{hangarInventorySlug}/stock" do
    parameter name: "hangarInventorySlug", in: :path, schema: {type: :string}, description: "Inventory slug"

    get("Hangar Inventory Stock") do
      operationId "hangarInventoryStock"
      tags "HangarInventoryStock"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarInventoryStockItemsList"
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
    create(:inventory_item, inventory: @inventory, name: "Quantanium", category: :commodity, quantity: 100, unit: :scu, entry_type: :deposit)
    create(:inventory_item, inventory: @inventory, name: "Quantanium", category: :commodity, quantity: 50, unit: :scu, entry_type: :deposit)
    create(:inventory_item, inventory: @inventory, name: "Quantanium", category: :commodity, quantity: 30, unit: :scu, entry_type: :withdrawal)
    create(:inventory_item, inventory: @inventory, name: "Medical Supplies", category: :consumable, quantity: 10, unit: :units, entry_type: :deposit)
  end

  test "GET /hangar/inventories/:slug/stock aggregates deposits minus withdrawals" do
    sign_in @user

    assert_api_response :get, 200, path_params: {hangarInventorySlug: @inventory.slug} do
      quantanium = parsed_body.find { |d| d["name"] == "Quantanium" }
      assert_equal 120.0, quantanium["netQuantity"]
      medical = parsed_body.find { |d| d["name"] == "Medical Supplies" }
      assert_equal 10.0, medical["netQuantity"]
    end
  end

  test "GET /hangar/inventories/:slug/stock returns 404 for another user's inventory" do
    sign_in @other_user

    assert_api_response :get, 404, path_params: {hangarInventorySlug: @inventory.slug}
  end

  test "GET /hangar/inventories/:slug/stock returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {hangarInventorySlug: @inventory.slug}
  end

  test "GET /hangar/inventories/:slug/stock with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {hangarInventorySlug: @inventory.slug},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:read"])
  end
end
