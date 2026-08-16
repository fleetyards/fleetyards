# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarInventoryItemsIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/inventories/{hangarInventorySlug}/items" do
    parameter name: "hangarInventorySlug", in: :path, schema: {type: :string}, description: "Inventory slug"

    get("Hangar Inventory Items List") do
      operationId "hangarInventoryItems"
      tags "HangarInventoryItems"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: InventoryItem.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/HangarInventoryItemQuery"
        },
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

  test "GET /hangar/inventories/:slug/items lists the ledger entries" do
    create_list(:inventory_item, 3, inventory: @inventory)
    sign_in @user

    assert_api_response :get, 200, path_params: {hangarInventorySlug: @inventory.slug} do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /hangar/inventories/:slug/items filters by category" do
    create(:inventory_item, inventory: @inventory, category: :commodity)
    create(:inventory_item, :component, inventory: @inventory)
    sign_in @user

    get "/api/v1/hangar/inventories/#{@inventory.slug}/items?q[categoryEq]=component"

    assert_response :success
    assert_equal 1, JSON.parse(response.body)["items"].count
  end

  test "GET /hangar/inventories/:slug/items returns 404 for another user's inventory" do
    sign_in @other_user

    assert_api_response :get, 404, path_params: {hangarInventorySlug: @inventory.slug}
  end

  test "GET /hangar/inventories/:slug/items returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {hangarInventorySlug: @inventory.slug}
  end

  test "GET /hangar/inventories/:slug/items with OAuth bearer token" do
    assert_api_response :get, 200,
      path_params: {hangarInventorySlug: @inventory.slug},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:read"])
  end
end
