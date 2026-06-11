# frozen_string_literal: true

require_relative "../../../openapi_helper"

class Api::V1::VehicleLoadoutsUpdateTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/vehicles/{vehicle_id}/loadouts/{id}" do
    parameter name: "vehicle_id", in: :path, description: "Vehicle id or serial", schema: {type: :string}
    parameter name: "id", in: :path, description: "Loadout id", schema: {type: :string, format: :uuid}

    put("Update Vehicle Loadout") do
      operationId "updateVehicleLoadout"
      tags "VehicleLoadouts"
      consumes "application/json"
      produces "application/json"

      request_body required: true, schema: {"$ref": "#/components/schemas/VehicleLoadoutInput"}

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

  test "PUT /vehicles/:vehicle_id/loadouts/:id updates the loadout" do
    loadout = create(:vehicle_loadout, vehicle: @vehicle)
    sign_in @user

    assert_api_response :put, 200,
      path_params: {vehicle_id: @vehicle.id, id: loadout.id},
      body: {name: "Updated Loadout", url: "https://erkul.games/loadout/updated123"} do
      assert_equal "Updated Loadout", parsed_body["name"]
    end
  end

  test "PUT /vehicles/:vehicle_id/loadouts/:id returns 404 for missing loadout" do
    sign_in @user

    assert_api_response :put, 404,
      path_params: {vehicle_id: @vehicle.id, id: SecureRandom.uuid},
      body: {name: "x", url: "https://erkul.games/loadout/x"}
  end

  test "PUT /vehicles/:vehicle_id/loadouts/:id returns 401 when not signed in" do
    loadout = create(:vehicle_loadout, vehicle: @vehicle)

    assert_api_response :put, 401,
      path_params: {vehicle_id: @vehicle.id, id: loadout.id},
      body: {name: "x", url: "https://erkul.games/loadout/x"}
  end

  test "PUT /vehicles/:vehicle_id/loadouts/:id with OAuth bearer token" do
    loadout = create(:vehicle_loadout, vehicle: @vehicle)

    assert_api_response :put, 200,
      path_params: {vehicle_id: @vehicle.id, id: loadout.id},
      headers: oauth_headers_for(@user, scopes: ["hangar", "hangar:write"]),
      body: {name: "Updated Loadout", url: "https://erkul.games/loadout/updated123"}
  end
end
