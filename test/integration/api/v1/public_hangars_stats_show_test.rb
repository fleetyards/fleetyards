# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PublicHangarsStatsShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/public/hangars/{username}/stats" do
    parameter name: "username", in: :path, schema: {type: :string}, description: "username"

    get("Public Hangar Stats") do
      operationId "publicHangarStats"
      tags "PublicHangarStats"
      produces "application/json"

      parameter name: "q", in: :query,
        schema: {
          type: :object,
          "$ref": "#/components/schemas/HangarQuery"
        },
        style: :deepObject,
        explode: true,
        required: false

      response(200, "successful") do
        schema "$ref": "#/components/schemas/HangarStatsPublic"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "GET /public/hangars/:username/stats returns stats for public hangar" do
    user = create(:user, public_hangar_stats: true, vehicle_count: 2, wanted_vehicle_count: 3)

    assert_api_response :get, 200, path_params: {username: user.username}
  end

  test "GET /public/hangars/:username/stats includes wishlist_total when public_wishlist enabled" do
    user = create(:user, public_hangar_stats: true, public_wishlist: true)
    create_list(:vehicle, 2, user: user)
    create_list(:vehicle, 3, user: user, wanted: true, public: true)

    assert_api_response :get, 200, path_params: {username: user.username} do
      assert_equal 3, parsed_body["wishlistTotal"]
    end
  end

  test "GET /public/hangars/:username/stats omits wishlist_total when public_wishlist disabled" do
    user = create(:user, public_hangar_stats: true, vehicle_count: 2, wanted_vehicle_count: 3, public_wishlist: false)

    assert_api_response :get, 200, path_params: {username: user.username} do
      assert_nil parsed_body["wishlistTotal"]
    end
  end

  test "GET /public/hangars/:username/stats returns 404 for non-public stats" do
    user = create(:user, public_hangar_stats: false, vehicle_count: 2)

    assert_api_response :get, 404, path_params: {username: user.username}
  end
end
