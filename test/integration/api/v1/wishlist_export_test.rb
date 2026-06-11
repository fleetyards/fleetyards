# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::WishlistExportTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/wishlist/export" do
    get("Export your Wishlist") do
      operationId "exportWishlist"
      tags "Wishlist"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/VehicleExport"}
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  test "GET /wishlist/export returns vehicle exports" do
    user = create(:user, wanted_vehicle_count: 2, vehicle_count: 3)
    sign_in user

    assert_api_response :get, 200 do
      assert_operator parsed_body.count, :>, 0
    end
  end

  test "GET /wishlist/export returns 401 when not signed in" do
    assert_api_response :get, 401
  end
end
