# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarInventoryItemsCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/inventories/{hangarInventorySlug}/items" do
    parameter name: "hangarInventorySlug", in: :path, schema: {type: :string}, description: "Inventory slug"

    post("Create Hangar Inventory Item") do
      operationId "createHangarInventoryItem"
      tags "HangarInventoryItems"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/HangarInventoryItemCreateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/HangarInventoryItem"
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
    Flipper.enable("hangar_inventories")
    @user = create(:user)
    @other_user = create(:user)
    @inventory = create(:hangar_inventory, user: @user)
  end

  def item_body(overrides = {})
    {name: "Quantanium", category: "commodity", quantity: 250.5, unit: "scu", entryType: "deposit"}.merge(overrides)
  end

  test "POST /hangar/inventories/:slug/items creates a deposit" do
    sign_in @user

    assert_api_response :post, 201,
      path_params: {hangarInventorySlug: @inventory.slug},
      body: item_body do
      assert_equal "Quantanium", parsed_body["name"]
      assert_equal "deposit", parsed_body["entryType"]
      assert_in_delta 250.5, parsed_body["quantity"]
    end
  end

  test "POST /hangar/inventories/:slug/items returns 400 for a zero quantity" do
    sign_in @user

    assert_api_response :post, 400,
      path_params: {hangarInventorySlug: @inventory.slug},
      body: item_body(quantity: 0)
  end

  test "POST /hangar/inventories/:slug/items returns 404 for another user's inventory" do
    sign_in @other_user

    assert_api_response :post, 404,
      path_params: {hangarInventorySlug: @inventory.slug},
      body: item_body
  end

  test "POST /hangar/inventories/:slug/items returns 401 when not signed in" do
    assert_api_response :post, 401,
      path_params: {hangarInventorySlug: @inventory.slug},
      body: item_body
  end

  test "POST /hangar/inventories/:slug/items with OAuth bearer token" do
    assert_api_response :post, 201,
      path_params: {hangarInventorySlug: @inventory.slug},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"]),
      body: item_body
  end
end
