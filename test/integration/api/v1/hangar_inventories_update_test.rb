# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarInventoriesUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/inventories/{slug}" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Inventory slug"

    put("Update Hangar Inventory") do
      operationId "updateHangarInventory"
      tags "HangarInventories"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/HangarInventoryUpdateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
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

  test "PUT /hangar/inventories/:slug updates the inventory" do
    sign_in @user

    assert_api_response :put, 200,
      path_params: {slug: @inventory.slug},
      body: {name: "Renamed Locker", location: "Lorville"} do
      assert_equal "Renamed Locker", parsed_body["name"]
      assert_equal "Lorville", parsed_body["location"]
    end
  end

  test "PUT /hangar/inventories/:slug returns 404 for another user's inventory" do
    sign_in @other_user

    assert_api_response :put, 404,
      path_params: {slug: @inventory.slug},
      body: {name: "Hijacked"}
  end

  test "PUT /hangar/inventories/:slug returns 401 when not signed in" do
    assert_api_response :put, 401,
      path_params: {slug: @inventory.slug},
      body: {name: "Renamed Locker"}
  end

  test "PUT /hangar/inventories/:slug with OAuth bearer token" do
    assert_api_response :put, 200,
      path_params: {slug: @inventory.slug},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"]),
      body: {name: "OAuth Rename"}
  end
end
