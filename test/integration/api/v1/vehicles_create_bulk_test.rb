# frozen_string_literal: true

require "openapi_helper"

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

      request_body required: true, schema: ::V1::Schemas::Inputs::VehicleCreateBulkInput

      response(204, "successful")

      response(400, "bad request - a ship that cannot be owned") do
        schema ::Shared::V1::Schemas::ValidationError
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
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

  # The picker used to offer these, which is where the reported 400s came from.
  test "POST /vehicles/bulk returns 400 for a model a player cannot own" do
    model = create(:model, player_ownable: false)
    sign_in @user

    assert_api_response :post, 400, body: {vehicles: [{modelId: model.id, wanted: false}]}

    assert_equal 0, Vehicle.count
  end

  # The message is built from `I18n.t("validation_error.#{code}")`, so a missing
  # key ships as the literal "translation missing: ..." string in the payload.
  test "POST /vehicles/bulk names the failure rather than reporting a missing translation" do
    model = create(:model, player_ownable: false)
    sign_in @user

    assert_api_response :post, 400, body: {vehicles: [{modelId: model.id, wanted: false}]}

    payload = response.parsed_body

    assert_equal "validation_error.vehicle.bulk_create", payload["code"]
    assert_equal "Some ships could not be added.", payload["message"]
    refute_includes payload["message"], "translation missing"
  end

  test "POST /vehicles/bulk returns 401 when not signed in" do
    model = create(:model)

    assert_api_response :post, 401, body: {vehicles: [{modelId: model.id, wanted: true}]}
  end

  test "POST /vehicles/bulk with OAuth bearer token" do
    model = create(:model)

    assert_api_response :post, 204,
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"]),
      body: {vehicles: [{modelId: model.id, wanted: true}]}
  end

  test "POST /vehicles/bulk returns 401 for OAuth token without write scope" do
    model = create(:model)

    assert_api_response :post, 401,
      headers: oauth_headers_for(@user, scopes: ["hangar:read"]),
      body: {vehicles: [{modelId: model.id, wanted: true}]}
  end
end
