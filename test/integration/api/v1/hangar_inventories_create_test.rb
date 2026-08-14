# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarInventoriesCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/inventories" do
    post("Create Hangar Inventory") do
      operationId "createInventory"
      tags "HangarInventories"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/HangarInventoryCreateInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/Inventory"
      end

      response(400, "validation error") do
        schema "$ref": "#/components/schemas/ValidationError"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    Flipper.enable("hangar_inventories")
    @user = create(:user)
  end

  test "POST /hangar/inventories creates an inventory" do
    sign_in @user

    assert_api_response :post, 201, body: {name: "Area 18 Locker", location: "ArcCorp"} do
      assert_equal "Area 18 Locker", parsed_body["name"]
      assert_equal "ArcCorp", parsed_body["location"]
      assert_predicate parsed_body["slug"], :present?
    end
  end

  test "POST /hangar/inventories returns 400 for duplicate name" do
    create(:inventory, holder: @user, name: "Area 18 Locker")
    sign_in @user

    assert_api_response :post, 400, body: {name: "Area 18 Locker"}
  end

  test "POST /hangar/inventories allows another user to reuse the same name" do
    create(:inventory, holder: create(:user), name: "Area 18 Locker")
    sign_in @user

    assert_api_response :post, 201, body: {name: "Area 18 Locker"}
  end

  test "POST /hangar/inventories returns 401 when not signed in" do
    assert_api_response :post, 401, body: {name: "x"}
  end

  test "POST /hangar/inventories with OAuth bearer token" do
    assert_api_response :post, 201,
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"]),
      body: {name: "OAuth Locker"}
  end
end
