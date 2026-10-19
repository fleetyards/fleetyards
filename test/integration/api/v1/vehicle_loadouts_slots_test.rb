# frozen_string_literal: true

require "openapi_helper"

class Api::V1::VehicleLoadoutsSlotsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/vehicles/{vehicle_id}/loadouts/{id}/slots" do
    parameter name: "vehicle_id", in: :path, description: "Vehicle id or serial", schema: {type: :string}
    parameter name: "id", in: :path, description: "Loadout id", schema: {type: :string, format: :uuid}

    get("Vehicle Loadout Slots") do
      operationId "vehicleLoadoutSlots"
      tags "VehicleLoadouts"
      produces "application/json"

      security [
        {SessionCookie: []},
        {Oauth2: ["hangar", "hangar:read"]},
        {OpenId: ["hangar", "hangar:read"]}
      ]

      response(200, "successful") do
        schema ::V1::Schemas::Loadouts::LoadoutSlotList
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
    create(:hardpoint, parent: model, sc_name: "hardpoint_power_plant", source: :game_files,
      types: ["PowerPlant"], min_size: 1, max_size: 1, component: stock)

    @loadout = @vehicle.vehicle_loadouts.create!(kind: "fleetyards",
      item_list: [{slot_path: "hardpoint_power_plant", item_type: "Component", item_id: @upgrade.id}])
  end

  test "GET /vehicles/:vehicle_id/loadouts/:id/slots names what is fitted beside the stock part" do
    sign_in @user

    assert_api_response :get, 200, path_params: {vehicle_id: @vehicle.id, id: @loadout.id} do
      plant = parsed_body.sole

      assert_equal "Stock Plant", plant.dig("stock", "name")
      assert_equal "Better Plant", plant.dig("fitted", "name")
    end
  end

  test "GET /vehicles/:vehicle_id/loadouts/:id/slots says which parts a recipe makes" do
    create(:blueprint, craftable: @upgrade)
    sign_in @user

    assert_api_response :get, 200, path_params: {vehicle_id: @vehicle.id, id: @loadout.id} do
      plant = parsed_body.sole

      assert plant.dig("fitted", "craftable")
      assert_equal false, plant.dig("stock", "craftable")
    end
  end

  test "GET /vehicles/:vehicle_id/loadouts/:id/slots returns 401 when not signed in" do
    assert_api_response :get, 401, path_params: {vehicle_id: @vehicle.id, id: @loadout.id}
  end

  test "GET /vehicles/:vehicle_id/loadouts/:id/slots returns 404 for another user's vehicle" do
    sign_in create(:user)

    assert_api_response :get, 404, path_params: {vehicle_id: @vehicle.id, id: @loadout.id}
  end
end
