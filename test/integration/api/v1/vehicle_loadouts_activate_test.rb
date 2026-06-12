# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::VehicleLoadoutsActivateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/vehicles/{vehicle_id}/loadouts/{id}/activate" do
    parameter name: "vehicle_id", in: :path, description: "Vehicle id or serial", schema: {type: :string}
    parameter name: "id", in: :path, description: "Loadout id", schema: {type: :string, format: :uuid}

    put("Activate Vehicle Loadout") do
      operationId "activateVehicleLoadout"
      tags "VehicleLoadouts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
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

  test "PUT /vehicles/:vehicle_id/loadouts/:id/activate activates the loadout" do
    loadout = create(:vehicle_loadout, vehicle: @vehicle)
    sign_in @user

    assert_api_response :put, 200, path_params: {vehicle_id: @vehicle.id, id: loadout.id}, body: {} do
      assert_equal true, parsed_body["active"]
    end
  end

  test "PUT /vehicles/:vehicle_id/loadouts/:id/activate deactivates other loadouts" do
    loadout = create(:vehicle_loadout, vehicle: @vehicle)
    other = create(:vehicle_loadout, :active, vehicle: @vehicle, name: "Other")
    sign_in @user

    assert_api_response :put, 200, path_params: {vehicle_id: @vehicle.id, id: loadout.id}, body: {} do
      assert_equal false, other.reload.active
    end
  end

  test "PUT /vehicles/:vehicle_id/loadouts/:id/activate returns 404 for missing loadout" do
    sign_in @user

    assert_api_response :put, 404, path_params: {vehicle_id: @vehicle.id, id: SecureRandom.uuid}, body: {}
  end

  test "PUT /vehicles/:vehicle_id/loadouts/:id/activate returns 401 when not signed in" do
    loadout = create(:vehicle_loadout, vehicle: @vehicle)

    assert_api_response :put, 401, path_params: {vehicle_id: @vehicle.id, id: loadout.id}, body: {}
  end

  test "PUT /vehicles/:vehicle_id/loadouts/:id/activate with OAuth bearer token" do
    loadout = create(:vehicle_loadout, vehicle: @vehicle)

    assert_api_response :put, 200,
      path_params: {vehicle_id: @vehicle.id, id: loadout.id},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"]),
      body: {}
  end
end
