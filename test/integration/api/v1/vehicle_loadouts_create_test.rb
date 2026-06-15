# frozen_string_literal: true

require "openapi_helper"

class Api::V1::VehicleLoadoutsCreateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/vehicles/{vehicle_id}/loadouts" do
    parameter name: "vehicle_id", in: :path, description: "Vehicle id or serial", schema: {type: :string}

    post("Create Vehicle Loadout") do
      operationId "createVehicleLoadout"
      tags "VehicleLoadouts"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/VehicleLoadoutInput"}

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(201, "successful") do
        schema "$ref": "#/components/schemas/VehicleLoadout"
      end

      response(401, "unauthorized") do
        schema "$ref": "#/components/schemas/StandardError"
      end

      response(404, "not found") do
        schema "$ref": "#/components/schemas/StandardError"
      end
    end
  end

  setup do
    @user = create(:user)
    @vehicle = create(:vehicle, user: @user)
  end

  test "POST /vehicles/:vehicle_id/loadouts creates a loadout" do
    sign_in @user

    assert_api_response :post, 201,
      path_params: {vehicle_id: @vehicle.id},
      body: {url: "https://erkul.games/loadout/abc123"} do
      assert_equal "https://erkul.games/loadout/abc123", parsed_body["url"]
    end
  end

  test "POST /vehicles/:vehicle_id/loadouts returns 404 for missing vehicle" do
    sign_in @user

    assert_api_response :post, 404,
      path_params: {vehicle_id: SecureRandom.uuid},
      body: {url: "https://erkul.games/loadout/x"}
  end

  test "POST /vehicles/:vehicle_id/loadouts returns 401 when not signed in" do
    assert_api_response :post, 401,
      path_params: {vehicle_id: @vehicle.id},
      body: {url: "https://erkul.games/loadout/x"}
  end

  test "POST /vehicles/:vehicle_id/loadouts with OAuth bearer token" do
    assert_api_response :post, 201,
      path_params: {vehicle_id: @vehicle.id},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"]),
      body: {url: "https://erkul.games/loadout/abc123"}
  end
end
