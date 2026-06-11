# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::HangarMoveAllIngameToWishlistTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hangar/move-all-ingame-to-wishlist" do
    put("Move all Ingame Ships from your Hangar to your Wishlist") do
      operationId "moveAllIngameToWishlist"
      tags "Hangar"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(204, "successful")

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "PUT /hangar/move-all-ingame-to-wishlist moves ingame ships to wishlist" do
    user = create(:user)
    create_list(:vehicle, 2, user: user, bought_via: :ingame)
    sign_in user

    assert_api_response :put, 204, body: {} do
      assert_equal 2, user.vehicles.where(wanted: true).count
      assert_equal 0, user.vehicles.where(wanted: false).count
    end
  end

  test "PUT /hangar/move-all-ingame-to-wishlist returns 401 when not signed in" do
    assert_api_response :put, 401, body: {}
  end

  test "PUT /hangar/move-all-ingame-to-wishlist with OAuth bearer token" do
    user = create(:user)
    create_list(:vehicle, 2, user: user, bought_via: :ingame)

    assert_api_response :put, 204,
      headers: oauth_headers_for(user, scopes: ["hangar", "hangar:write"]),
      body: {}
  end
end
