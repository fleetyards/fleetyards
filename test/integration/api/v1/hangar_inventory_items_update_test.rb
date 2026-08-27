# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarInventoryItemsUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/inventories/{hangarInventorySlug}/items/{id}" do
    parameter name: "hangarInventorySlug", in: :path, schema: {type: :string}, description: "Inventory slug"
    parameter name: "id", in: :path, schema: {type: :string}, description: "Inventory item ID"

    put("Update Hangar Inventory Item") do
      operationId "updateHangarInventoryItem"
      tags "HangarInventoryItems"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: ::V1::Schemas::Inputs::HangarInventoryItemUpdateInput

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Hangar::Logistics::HangarInventoryItem
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("hangar_inventories")
    @user = create(:user)
    @other_user = create(:user)
    @inventory = create(:inventory, holder: @user)
    @item = create(:inventory_item, inventory: @inventory)
  end

  test "PUT /hangar/inventories/:slug/items/:id updates the entry" do
    sign_in @user

    assert_api_response :put, 200,
      path_params: {hangarInventorySlug: @inventory.slug, id: @item.id},
      body: {name: "Renamed Cargo", notes: "moved to hold 2"} do
      assert_equal "Renamed Cargo", parsed_body["name"]
      assert_equal "moved to hold 2", parsed_body["notes"]
    end
  end

  test "PUT /hangar/inventories/:slug/items/:id returns 404 for another user's item" do
    sign_in @other_user

    assert_api_response :put, 404,
      path_params: {hangarInventorySlug: @inventory.slug, id: @item.id},
      body: {name: "Hijacked"}
  end

  test "PUT /hangar/inventories/:slug/items/:id returns 401 when not signed in" do
    assert_api_response :put, 401,
      path_params: {hangarInventorySlug: @inventory.slug, id: @item.id},
      body: {name: "Renamed Cargo"}
  end

  test "PUT /hangar/inventories/:slug/items/:id with OAuth bearer token" do
    assert_api_response :put, 200,
      path_params: {hangarInventorySlug: @inventory.slug, id: @item.id},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"]),
      body: {name: "OAuth Rename"}
  end
end
