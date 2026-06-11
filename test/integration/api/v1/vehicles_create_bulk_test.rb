# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::VehiclesCreateBulkTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/vehicles/bulk" do
    post("Create multiple vehicles") do
      operationId "createBulkVehicle"
      tags "Vehicles"
      consumes "application/json"
      produces "application/json"

      security [{
        SessionCookie: [],
        Oauth2: ["hangar", "hangar:write"],
        OpenId: ["hangar", "hangar:write"]
      }]

      request_body required: true, schema: {"$ref": "#/components/schemas/VehicleCreateBulkInput"}

      response(204, "successful")

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @user = create(:user)
  end

  test "POST /vehicles/bulk creates multiple vehicles" do
    model = create(:model)
    sign_in @user

    assert_api_response :post, 204, body: {vehicles: [{modelId: model.id, wanted: true}]}
  end

  test "POST /vehicles/bulk returns 401 when not signed in" do
    model = create(:model)

    assert_api_response :post, 401, body: {vehicles: [{modelId: model.id, wanted: true}]}
  end

  test "POST /vehicles/bulk with OAuth bearer token" do
    model = create(:model)

    assert_api_response :post, 204,
      headers: oauth_headers_for(@user, scopes: ["hangar:write"]),
      body: {vehicles: [{modelId: model.id, wanted: true}]}
  end
end
