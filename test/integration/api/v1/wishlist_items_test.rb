# frozen_string_literal: true

require "openapi_helper"

class Api::V1::WishlistItemsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/wishlist/items" do
    get("Your Wishlist items") do
      operationId "wishlistItems"
      tags "Wishlist"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema type: :array, items: {type: :string}
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "GET /wishlist/items returns the wanted item names" do
    user = create(:user, wanted_vehicle_count: 2, vehicle_count: 3)
    sign_in user

    assert_api_response :get, 200 do
      assert_operator parsed_body.count, :>, 0
    end
  end

  test "GET /wishlist/items returns 401 when not signed in" do
    assert_api_response :get, 401
  end

  test "GET /wishlist/items with OAuth bearer token" do
    user = create(:user, wanted_vehicle_count: 2, vehicle_count: 3)

    assert_api_response :get, 200, headers: oauth_headers_for(user, scopes: ["hangar", "hangar:read"])
  end
end
