# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarAllInventoryItemsIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/inventory-items" do
    get("Hangar All Inventory Items") do
      operationId "hangarAllInventoryItems"
      tags "HangarInventoryItems"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: InventoryItem.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {"$ref": "#/components/schemas/HangarInventoryItemQuery"},
        style: :deepObject,
        explode: true,
        required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarInventoryItemsList"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    Flipper.enable("hangar_inventories")
    @user = create(:user)
    @other_user = create(:user)
    @inventory = create(:inventory, holder: @user, name: "Mining Ops")
    @other_inventory = create(:inventory, holder: @user, name: "Medical Bay")
  end

  test "GET /hangar/inventory-items lists entries across all inventories" do
    create_list(:inventory_item, 2, inventory: @inventory)
    create_list(:inventory_item, 3, inventory: @other_inventory)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 5, parsed_body["items"].count
    end
  end

  test "GET /hangar/inventory-items leaves out a ship's entries while ship_inventories is off" do
    Flipper.disable("ship_inventories")
    aboard = create(:inventory, holder: @user, vehicle: create(:vehicle, user: @user))
    create_list(:inventory_item, 2, inventory: @inventory)
    create_list(:inventory_item, 3, inventory: aboard)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 2, parsed_body["items"].count
    end
  end

  test "GET /hangar/inventory-items includes a ship's entries when ship_inventories is enabled" do
    Flipper.enable("ship_inventories")
    aboard = create(:inventory, holder: @user, vehicle: create(:vehicle, user: @user))
    create_list(:inventory_item, 2, inventory: @inventory)
    create_list(:inventory_item, 3, inventory: aboard)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 5, parsed_body["items"].count
    end
  end

  test "GET /hangar/inventory-items does not include other users' entries" do
    create_list(:inventory_item, 2, inventory: create(:inventory, holder: @other_user))
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 0, parsed_body["items"].count
    end
  end

  test "GET /hangar/inventory-items returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /hangar/inventory-items with OAuth bearer token" do
    assert_api_response :get, 200,
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:read"])
  end
end
