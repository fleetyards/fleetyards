# frozen_string_literal: true

require "openapi_helper"

class Api::V1::VehicleLoadoutsIndexTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/vehicles/{vehicle_id}/loadouts" do
    parameter name: "vehicle_id", in: :path, description: "Vehicle id or serial", schema: {type: :string}

    get("List Vehicle Loadouts") do
      operationId "vehicleLoadouts"
      tags "VehicleLoadouts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema type: :array, items: {"$ref": "#/components/schemas/VehicleLoadout"}
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

  test "GET /vehicles/:vehicle_id/loadouts lists loadouts" do
    create(:vehicle_loadout, vehicle: @vehicle)
    sign_in @user

    assert_api_response :get, 200, path_params: {vehicle_id: @vehicle.id} do
      assert_equal 1, parsed_body.count
    end
  end

  test "GET /vehicles/:vehicle_id/loadouts returns 404 for missing vehicle" do
    sign_in @user

    assert_api_response :get, 404, path_params: {vehicle_id: SecureRandom.uuid}
  end

  test "GET /vehicles/:vehicle_id/loadouts returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {vehicle_id: @vehicle.id}
  end

  test "GET /vehicles/:vehicle_id/loadouts with OAuth bearer token" do
    create(:vehicle_loadout, vehicle: @vehicle)

    assert_api_response :get, 200,
      path_params: {vehicle_id: @vehicle.id},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:read"])
  end
end
