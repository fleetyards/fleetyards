# frozen_string_literal: true

require "openapi_helper"

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

      request_body required: true, schema: ::V1::Schemas::Inputs::VehicleLoadoutInput

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Vehicles::VehicleLoadout
      end

      response(401, "unauthorized") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @user = create(:user)
    @vehicle = create(:vehicle, user: @user, model: create(:model, production_status: "flight-ready"))
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

  def fittable_module(slot)
    model_module = create(:model_module)
    create(:module_hardpoint, model: @vehicle.model, model_module:, slot:)
    @vehicle.update!(model_module_ids: @vehicle.model_module_ids + [model_module.id])
    model_module
  end

  test "PUT /vehicles/:vehicle_id/loadouts/:id replaces the fitting" do
    old = fittable_module("hardpoint_module")
    new = fittable_module("hardpoint_module")
    loadout = create(:vehicle_loadout, :fleetyards, vehicle: @vehicle,
      item_list: [{slot: "hardpoint_module", model_module_id: old.id}])
    sign_in @user

    assert_api_response :put, 200,
      path_params: {vehicle_id: @vehicle.id, id: loadout.id},
      body: {items: [{slot: "hardpoint_module", modelModuleId: new.id}]} do
      assert_equal [new.id], parsed_body["items"].pluck("modelModuleId")
    end
  end
end
