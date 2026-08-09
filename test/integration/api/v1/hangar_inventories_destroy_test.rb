# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarInventoriesDestroyTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/inventories/{slug}" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Inventory slug"

    delete("Delete Hangar Inventory") do
      operationId "destroyHangarInventory"
      tags "HangarInventories"

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
    @inventory = create(:hangar_inventory, user: @user)
  end

  test "DELETE /hangar/inventories/:slug deletes the inventory" do
    sign_in @user

    assert_difference "HangarInventory.count", -1 do
      assert_api_response :delete, 204, path_params: {slug: @inventory.slug}
    end
  end

  test "DELETE /hangar/inventories/:slug also deletes its items" do
    create_list(:hangar_inventory_item, 2, hangar_inventory: @inventory)
    sign_in @user

    assert_difference "HangarInventoryItem.count", -2 do
      assert_api_response :delete, 204, path_params: {slug: @inventory.slug}
    end
  end

  test "DELETE /hangar/inventories/:slug returns 404 for another user's inventory" do
    sign_in @other_user

    assert_api_response :delete, 404, path_params: {slug: @inventory.slug}
  end

  test "DELETE /hangar/inventories/:slug returns 401 when not signed in" do
    assert_api_response :delete, 401, path_params: {slug: @inventory.slug}
  end

  test "DELETE /hangar/inventories/:slug with OAuth bearer token" do
    assert_api_response :delete, 204,
      path_params: {slug: @inventory.slug},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"])
  end
end
