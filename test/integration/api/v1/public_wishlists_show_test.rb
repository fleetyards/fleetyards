# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::PublicWishlistsShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/public/wishlists/{username}" do
    parameter name: "username", in: :path, schema: {type: :string}, required: true

    get("Your Wishlist") do
      operationId "publicWishlist"
      tags "PublicWishlist"
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

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarPublic"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "GET /public/wishlists/:username returns wishlist items" do
    user = create(:user, public_wishlist: true, wanted_vehicle_count: 2)

    assert_api_response :get, 200, path_params: {username: user.username} do
      assert_operator parsed_body["items"].count, :>, 0
    end
  end

  test "GET /public/wishlists/:username filters by query" do
    user = create(:user, public_wishlist: true, wanted_vehicle_count: 2)

    assert_api_response :get, 200,
      path_params: {username: user.username},
      params: {q: {"modelNameOrModelDescriptionCont" => user.vehicles.first.model.name}} do
      assert_equal 1, parsed_body["items"].count
    end
  end

  test "GET /public/wishlists/:username honours perPage" do
    user = create(:user, public_wishlist: true, wanted_vehicle_count: 2)

    assert_api_response :get, 200, path_params: {username: user.username}, params: {perPage: 1} do
      assert_equal 1, parsed_body["items"].count
    end
  end

  test "GET /public/wishlists/:username returns 404 for unknown username" do
    assert_api_response :get, 404, path_params: {username: "invalid"}
  end

  test "GET /public/wishlists/:username returns 404 when wishlist is private" do
    user = create(:user, public_wishlist: false, wanted_vehicle_count: 2)

    assert_api_response :get, 404, path_params: {username: user.username}
  end
end
