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

      request_body required: true, schema: ::V1::Schemas::Inputs::VehicleLoadoutInput

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:write"]},
        {OpenId: ["hangar", "hangar:write"]}
      ]

      response(201, "successful") do
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

  def fittable_module(slot)
    model_module = create(:model_module)
    create(:module_hardpoint, model: @vehicle.model, model_module:, slot:)
    @vehicle.update!(model_module_ids: @vehicle.model_module_ids + [model_module.id])
    model_module
  end

  test "POST /vehicles/:vehicle_id/loadouts creates a fleetyards loadout with one module per slot" do
    front = fittable_module("hardpoint_front_module")
    rear = fittable_module("hardpoint_rear_module")
    sign_in @user

    assert_api_response :post, 201,
      path_params: {vehicle_id: @vehicle.id},
      body: {
        kind: "fleetyards",
        items: [
          {slotPath: "hardpoint_front_module", itemType: "ModelModule", itemId: front.id},
          {slotPath: "hardpoint_rear_module", itemType: "ModelModule", itemId: rear.id}
        ]
      } do
      assert_equal "fleetyards", parsed_body["kind"]
      assert_not parsed_body.key?("url")
      assert_equal [front.id, rear.id], parsed_body["items"].pluck("itemId")
    end
  end

  test "POST /vehicles/:vehicle_id/loadouts refuses two modules in one slot" do
    first = fittable_module("hardpoint_module")
    second = fittable_module("hardpoint_module")
    sign_in @user

    post "/api/v1/vehicles/#{@vehicle.id}/loadouts", as: :json, params: {
      kind: "fleetyards",
      items: [
        {slotPath: "hardpoint_module", itemType: "ModelModule", itemId: first.id},
        {slotPath: "hardpoint_module", itemType: "ModelModule", itemId: second.id}
      ]
    }

    assert_response :bad_request
    assert_equal "validation_error.vehicle_loadout.create", response.parsed_body["code"]
    assert_equal ["slot_taken"], response.parsed_body["errors"].first["messages"].pluck("code")
    assert_empty @vehicle.vehicle_loadouts
  end

  test "POST /vehicles/:vehicle_id/loadouts refuses a ship that is not flight-ready" do
    @vehicle.model.update!(production_status: "in-concept")
    sign_in @user

    post "/api/v1/vehicles/#{@vehicle.id}/loadouts", as: :json, params: {url: "https://erkul.games/loadout/x"}

    assert_response :bad_request
  end
end
