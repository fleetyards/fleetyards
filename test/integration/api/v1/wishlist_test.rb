# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::WishlistTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/wishlist" do
    delete("Clear your Wishlist") do
      operationId "destroyWishlist"
      tags "Wishlist"
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

    get("Your Wishlist") do
      operationId "wishlist"
      tags "Wishlist"
      produces "application/json"

      parameter name: "page", in: :query, schema: {type: :string, default: "1"}, required: false
      parameter name: "perPage", in: :query, schema: {type: :string, default: Vehicle.default_per_page}, required: false
      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/HangarQuery"
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
        schema "$ref": "#/components/schemas/Hangar"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "DELETE /wishlist clears the wishlist" do
    user = create(:user, wanted_vehicle_count: 2, vehicle_count: 3)
    sign_in user

    assert_api_response :delete, 204 do
      assert_equal 0, user.vehicles.where(wanted: true).count
    end
  end

  test "DELETE /wishlist returns 401 when not signed in" do
    assert_api_response :delete, 401
  end

  test "GET /wishlist returns the wanted vehicles" do
    user = create(:user, vehicle_count: 3)
    create_list(:vehicle, 2, user: user, wanted: true)
    sign_in user

    assert_api_response :get, 200 do
      assert_operator parsed_body["items"].count, :>, 0
    end
  end

  test "GET /wishlist filters by query" do
    user = create(:user, vehicle_count: 3)
    wanted = create_list(:vehicle, 2, user: user, wanted: true)
    sign_in user

    assert_api_response :get, 200, params: {q: {"modelNameOrModelDescriptionCont" => wanted.first.model.name}} do
      assert_equal 1, parsed_body["items"].count
    end
  end

  test "GET /wishlist honours perPage" do
    user = create(:user, vehicle_count: 3)
    create_list(:vehicle, 2, user: user, wanted: true)
    sign_in user

    assert_api_response :get, 200, params: {perPage: 1} do
      assert_equal 1, parsed_body["items"].count
    end
  end

  test "GET /wishlist returns 401 when not signed in" do
    assert_api_response :get, 401
  end
end
