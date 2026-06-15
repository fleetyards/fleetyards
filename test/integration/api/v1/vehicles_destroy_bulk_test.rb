# frozen_string_literal: true

require "openapi_helper"

class Api::V1::VehiclesDestroyBulkTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/vehicles/destroy-bulk" do
    put("Destroy multiple Vehicles") do
      operationId "destroyBulkVehicle"
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/VehicleDestroyBulkInput"}

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

  setup do
    @user = create(:user)
  end

  test "PUT /vehicles/destroy-bulk destroys the listed vehicles" do
    vehicles = create_list(:vehicle, 3, user: @user)
    sign_in @user

    assert_api_response :put, 204, body: {ids: vehicles.map(&:id)}
  end

  test "PUT /vehicles/destroy-bulk returns 401 when not signed in" do
    vehicles = create_list(:vehicle, 3, user: @user)

    assert_api_response :put, 401, body: {ids: vehicles.map(&:id)}
  end

  test "PUT /vehicles/destroy-bulk with OAuth bearer token" do
    vehicles = create_list(:vehicle, 3, user: @user)

    assert_api_response :put, 204,
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"]),
      body: {ids: vehicles.map(&:id)}
  end
end
