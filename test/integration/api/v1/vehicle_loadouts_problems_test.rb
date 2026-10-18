# frozen_string_literal: true

require "openapi_helper"

class Api::V1::VehicleLoadoutsProblemsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/vehicles/{vehicle_id}/loadouts/{id}/problems" do
    parameter name: "vehicle_id", in: :path, description: "Vehicle id or serial", schema: {type: :string}
    parameter name: "id", in: :path, description: "Loadout id", schema: {type: :string, format: :uuid}

    get("Vehicle Loadout Problems") do
      operationId "vehicleLoadoutProblems"
      tags "VehicleLoadouts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Loadouts::LoadoutItemProblemList
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
    model = create(:model, production_status: "flight-ready")
    @vehicle = create(:vehicle, user: @user, model:)

    stock = create(:component, name: "Stock Plant", component_type: "PowerPlant", category: "powerplant", size: "1")
    @upgrade = create(:component, name: "Better Plant", component_type: "PowerPlant", category: "powerplant", size: "1")
    @cooler = create(:component, name: "Better Cooler", component_type: "Cooler", category: "cooler", size: "1")
    @plant_port = create(:hardpoint, parent: model, sc_name: "hardpoint_power_plant", source: :game_files,
      types: ["PowerPlant"], min_size: 1, max_size: 1, component: stock)
    @cooler_port = create(:hardpoint, parent: model, sc_name: "hardpoint_cooler", source: :game_files,
      types: ["Cooler"], min_size: 1, max_size: 1, component: create(:component, component_type: "Cooler",
        category: "cooler", size: "1"))

    @loadout = @vehicle.vehicle_loadouts.create!(kind: "fleetyards", item_list: [
      {slot_path: "hardpoint_power_plant", item_type: "Component", item_id: @upgrade.id},
      {slot_path: "hardpoint_cooler", item_type: "Component", item_id: @cooler.id}
    ])
  end

  test "GET /vehicles/:vehicle_id/loadouts/:id/problems names the items a new build refuses, and why" do
    sign_in @user
    @plant_port.build.update!(max_size: 0)
    @cooler_port.destroy!

    assert_api_response :get, 200, path_params: {vehicle_id: @vehicle.id, id: @loadout.id} do
      assert_equal [
        {"slotPath" => "hardpoint_cooler", "itemType" => "Component", "itemId" => @cooler.id,
         "itemName" => "Better Cooler", "code" => "slot_unknown"},
        {"slotPath" => "hardpoint_power_plant", "itemType" => "Component", "itemId" => @upgrade.id,
         "itemName" => "Better Plant", "code" => "component_not_in_slot"}
      ], parsed_body
    end
  end

  test "GET /vehicles/:vehicle_id/loadouts/:id/problems is empty while everything still fits" do
    sign_in @user

    assert_api_response :get, 200, path_params: {vehicle_id: @vehicle.id, id: @loadout.id} do
      assert_empty parsed_body
    end
  end

  test "GET /vehicles/:vehicle_id/loadouts/:id/problems returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {vehicle_id: @vehicle.id, id: @loadout.id}
  end

  test "GET /vehicles/:vehicle_id/loadouts/:id/problems returns 404 for another user's vehicle" do
    sign_in create(:user)

    assert_api_response :get, 404, path_params: {vehicle_id: @vehicle.id, id: @loadout.id}
  end
end
