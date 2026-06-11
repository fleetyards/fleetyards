# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::VehiclesCheckSerialTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/vehicles/check-serial" do
    post("Check Vehicle Serial") do
      operationId "checkSerialVehicle"
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/CheckInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema "$ref": "#/components/schemas/Check"
      end

      response(401, "unauthorized with wrong scope token") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @user = create(:user)
  end

  test "POST /vehicles/check-serial reports taken serials" do
    create(:vehicle, serial: "DO-5920-FL", user: @user)
    sign_in @user

    assert_api_response :post, 200, body: {value: "DO-5920-FL"} do
      assert_equal true, parsed_body["taken"]
    end
  end

  test "POST /vehicles/check-serial reports availability" do
    sign_in @user

    assert_api_response :post, 200, body: {value: "DO-9999-XX"} do
      assert_equal false, parsed_body["taken"]
    end
  end

  test "POST /vehicles/check-serial with OAuth bearer token" do
    assert_api_response :post, 200,
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:read"]),
      body: {value: "DO-1234-AB"}
  end

  test "POST /vehicles/check-serial returns 401 for OAuth bearer with wrong scope" do
    assert_api_response :post, 401,
      headers: oauth_headers_for(@user, scopes: ["public"]),
      body: {value: "DO-1234-AB"}
  end

  test "POST /vehicles/check-serial returns 401 when not signed in" do
    assert_api_response :post, 401, body: {value: "DO-1234-AB"}
  end
end
