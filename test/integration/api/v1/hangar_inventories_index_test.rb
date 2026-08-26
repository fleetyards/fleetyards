# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HangarInventoriesIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/inventories" do
    get("Hangar Inventories List") do
      operationId "hangarInventories"
      tags "HangarInventories"
      produces "application/json"

      parameter "$ref": "#/components/parameters/PageParameter"
      parameter name: "perPage", in: :query, schema: {type: :string, default: Inventory.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {"$ref": "#/components/schemas/HangarInventoryQuery"},
        style: :deepObject,
        explode: true,
        required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarInventoriesList"
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
  end

  test "GET /hangar/inventories lists the current user's inventories" do
    create_list(:inventory, 3, holder: @user)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /hangar/inventories does not list other users' inventories" do
    create_list(:inventory, 2, holder: @other_user)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 0, parsed_body["items"].count
    end
  end

  test "GET /hangar/inventories is allowed when hangar_inventories is enabled for the user actor" do
    Flipper.disable("hangar_inventories")
    Flipper.enable_actor("hangar_inventories", @user)
    create_list(:inventory, 3, holder: @user)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 3, parsed_body["items"].count
    end
  end

  test "GET /hangar/inventories lists ship inventories when ship_inventories is enabled" do
    Flipper.enable("ship_inventories")
    create(:inventory, holder: @user)
    create(:inventory, holder: @user, vehicle: create(:vehicle, user: @user))
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 2, parsed_body["items"].count
    end
  end

  test "GET /hangar/inventories leaves out ship inventories when ship_inventories is disabled" do
    Flipper.disable("ship_inventories")
    create(:inventory, holder: @user)
    create(:inventory, holder: @user, vehicle: create(:vehicle, user: @user))
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 1, parsed_body["items"].count
      assert_nil parsed_body["items"].first["vehicle"]
    end
  end

  test "GET /hangar/inventories is forbidden when hangar_inventories is disabled" do
    Flipper.disable("hangar_inventories")
    sign_in @user

    get "/api/v1/hangar/inventories"

    assert_response :forbidden
  end

  test "GET /hangar/inventories returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /hangar/inventories with OAuth bearer token" do
    assert_api_response :get, 200,
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:read"])
  end
end
