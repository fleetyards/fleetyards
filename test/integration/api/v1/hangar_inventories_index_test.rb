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
        schema: ::V1::Schemas::Queries::HangarInventoryQuery,
        style: :deepObject,
        explode: true,
        required: false

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Hangar::Logistics::HangarInventoriesList
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @user = create(:user)
    @other_user = create(:user)
  end

  test "GET /hangar/inventories lists the current user's inventories" do
    create_list(:inventory, 3, holder: @user)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 3, hand_made_items.count
    end
  end

  test "GET /hangar/inventories provides the personal inventory and lists it first" do
    create(:inventory, holder: @user, name: "Alpha")
    sign_in @user

    assert_api_response :get, 200 do
      first = parsed_body["items"].first

      assert_equal Inventory::PERSONAL_NAME, first["name"]
      assert first["personal"]
      assert_equal 1, parsed_body["items"].count { |item| item["personal"] }
    end
  end

  # The deposit pickers read the list whole.
  test "GET /hangar/inventories answers perPage=all with every inventory" do
    create_list(:inventory, Inventory.default_per_page + 1, holder: @user)
    sign_in @user

    assert_api_response :get, 200, params: {perPage: "all"} do
      assert_equal Inventory.default_per_page + 1, hand_made_items.count
    end
  end

  test "GET /hangar/inventories sorts by either sort key" do
    create(:inventory, holder: @user, name: "Alpha")
    create(:inventory, holder: @user, name: "Zebra")
    sign_in @user

    %i[s sorts].each do |key|
      assert_api_response :get, 200, params: {q: {key => "name desc"}} do
        assert_equal [Inventory::PERSONAL_NAME, "Zebra", "Alpha"], parsed_body["items"].map { |item| item["name"] }, key
      end
    end
  end

  test "GET /hangar/inventories does not list other users' inventories" do
    create_list(:inventory, 2, holder: @other_user)
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 0, hand_made_items.count
    end
  end

  test "GET /hangar/inventories lists ship inventories" do
    create(:inventory, holder: @user)
    create(:inventory, holder: @user, vehicle: create(:vehicle, user: @user))
    sign_in @user

    assert_api_response :get, 200 do
      assert_equal 2, hand_made_items.count
    end
  end

  test "GET /hangar/inventories says whether a ship inventory's ship is on the wishlist" do
    create(:inventory, holder: @user, vehicle: create(:vehicle, user: @user, wanted: true))
    sign_in @user

    assert_api_response :get, 200 do
      assert(parsed_body["items"].find { |item| item["vehicle"] }["vehicle"]["wanted"])
    end
  end

  test "GET /hangar/inventories returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /hangar/inventories with OAuth bearer token" do
    assert_api_response :get, 200,
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:read"])
  end

  private def hand_made_items
    parsed_body["items"].reject { |item| item["personal"] }
  end
end
