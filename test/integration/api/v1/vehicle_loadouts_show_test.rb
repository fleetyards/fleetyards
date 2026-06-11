# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::VehicleLoadoutsShowTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/vehicles/{vehicle_id}/loadouts/{id}" do
    parameter name: "vehicle_id", in: :path, description: "Vehicle id or serial", schema: {type: :string}
    parameter name: "id", in: :path, description: "Loadout id", schema: {type: :string, format: :uuid}

    get("Show Vehicle Loadout") do
      operationId "vehicleLoadout"
      tags "VehicleLoadouts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
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

  test "GET /vehicles/:vehicle_id/loadouts/:id returns the loadout" do
    loadout = create(:vehicle_loadout, vehicle: @vehicle)
    sign_in @user

    assert_api_response :get, 200, path_params: {vehicle_id: @vehicle.id, id: loadout.id}
  end

  test "GET /vehicles/:vehicle_id/loadouts/:id returns 404 for missing loadout" do
    sign_in @user

    assert_api_response :get, 404, path_params: {vehicle_id: @vehicle.id, id: SecureRandom.uuid}
  end

  test "GET /vehicles/:vehicle_id/loadouts/:id returns 401 when not signed in" do
    loadout = create(:vehicle_loadout, vehicle: @vehicle)

    assert_api_response :get, 401, path_params: {vehicle_id: @vehicle.id, id: loadout.id}
  end

  test "GET /vehicles/:vehicle_id/loadouts/:id with OAuth bearer token" do
    loadout = create(:vehicle_loadout, vehicle: @vehicle)

    assert_api_response :get, 200,
      path_params: {vehicle_id: @vehicle.id, id: loadout.id},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:read"])
  end
end
