# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarInventoriesShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/inventories/{slug}" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Inventory slug"

    get("Hangar Inventory") do
      operationId "hangarInventory"
      tags "HangarInventories"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarInventory"
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
  end

  test "GET /hangar/inventories/:slug returns the inventory" do
    sign_in @user

    assert_api_response :get, 200, path_params: {slug: @inventory.slug} do
      assert_equal @inventory.name, parsed_body["name"]
    end
  end

  test "GET /hangar/inventories/:slug returns 404 for unknown inventory" do
    sign_in @user

    assert_api_response :get, 404, path_params: {slug: "unknown"}
  end

  test "GET /hangar/inventories/:slug returns 404 for another user's inventory" do
    sign_in @other_user

    assert_api_response :get, 404, path_params: {slug: @inventory.slug}
  end

  test "GET /hangar/inventories/:slug returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {slug: @inventory.slug}
  end

  test "GET /hangar/inventories/:slug with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {slug: @inventory.slug},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:read"])
  end
end
