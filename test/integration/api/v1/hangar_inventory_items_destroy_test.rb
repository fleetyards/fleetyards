# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarInventoryItemsDestroyTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/inventories/{hangarInventorySlug}/items/{id}" do
    parameter name: "hangarInventorySlug", in: :path, schema: {type: :string}, description: "Inventory slug"
    parameter name: "id", in: :path, schema: {type: :string}, description: "Inventory item ID"

    delete("Delete Hangar Inventory Item") do
      operationId "destroyInventoryItem"
      tags "HangarInventoryItems"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(204, "successful")

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
    @item = create(:inventory_item, inventory: @inventory)
  end

  test "DELETE /hangar/inventories/:slug/items/:id deletes the entry" do
    sign_in @user

    assert_difference "InventoryItem.count", -1 do
      assert_api_response :delete, 204, path_params: {hangarInventorySlug: @inventory.slug, id: @item.id}
    end
  end

  test "DELETE /hangar/inventories/:slug/items/:id returns 404 for another user's item" do
    sign_in @other_user

    assert_api_response :delete, 404, path_params: {hangarInventorySlug: @inventory.slug, id: @item.id}
  end

  test "DELETE /hangar/inventories/:slug/items/:id returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: {hangarInventorySlug: @inventory.slug, id: @item.id}
  end

  test "DELETE /hangar/inventories/:slug/items/:id with OAuth bearer token" do
    assert_api_response :delete, 204,
      path_params: {hangarInventorySlug: @inventory.slug, id: @item.id},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"])
  end
end
