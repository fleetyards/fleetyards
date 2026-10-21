# frozen_string_literal: true

require "openapi_helper"

class Api::V1::PublicHangarsVehicleLoadoutsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  SHOW = "/public/hangars/{username}/vehicles/{vehicle_id}/loadouts/{id}"
  SLOTS = "/public/hangars/{username}/vehicles/{vehicle_id}/loadouts/{id}/slots"

  openapi_schema :"v1/schema"

  api_path SHOW do
    parameter name: "username", in: :path, schema: {type: :string}, description: "Username", required: true
    parameter name: "vehicle_id", in: :path, schema: {type: :string}, description: "Vehicle id or serial", required: true
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "Loadout id", required: true

    get("Public Vehicle Loadout") do
      operationId "publicVehicleLoadout"
      tags "PublicVehicleLoadouts"
      produces "application/json"

      parameter name: "share", in: :query, schema: {type: :string}, required: false, description: "Hangar share token"

      response(200, "successful") do
        schema ::V1::Schemas::Vehicles::VehicleLoadout
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  api_path SLOTS do
    parameter name: "username", in: :path, schema: {type: :string}, description: "Username", required: true
    parameter name: "vehicle_id", in: :path, schema: {type: :string}, description: "Vehicle id or serial", required: true
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "Loadout id", required: true

    get("Public Vehicle Loadout Slots") do
      operationId "publicVehicleLoadoutSlots"
      tags "PublicVehicleLoadouts"
      produces "application/json"

      parameter name: "share", in: :query, schema: {type: :string}, required: false, description: "Hangar share token"

      response(200, "successful") do
        schema ::V1::Schemas::Loadouts::LoadoutSlotList
      end

      response(403, "forbidden") do
        schema ::Shared::V1::Schemas::StandardError
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("vehicle_overview")
    @user = create(:user, public_hangar: true)
    model = create(:model, production_status: "flight-ready")
    @vehicle = create(:vehicle, user: @user, model:, public: true)

    stock = create(:component, name: "Stock Plant", component_type: "PowerPlant", category: "powerplant", size: "1")
    upgrade = create(:component, name: "Better Plant", component_type: "PowerPlant", category: "powerplant", size: "1")
    create(:hardpoint, parent: model, sc_name: "hardpoint_power_plant", source: :game_files,
      types: ["PowerPlant"], min_size: 1, max_size: 1, component: stock)

    @loadout = @vehicle.vehicle_loadouts.create!(kind: "fleetyards", name: "Hauler", public: true,
      item_list: [{slot_path: "hardpoint_power_plant", item_type: "Component", item_id: upgrade.id}])
  end

  private def path(vehicle: @vehicle, loadout: @loadout)
    {username: @user.username, vehicle_id: vehicle.id, id: loadout.id}
  end

  test "GET /public/hangars/:username/vehicles/:vehicle_id/loadouts/:id shows a public ship's loadout" do
    assert_api_response :get, 200, api_path: SHOW, path_params: path do
      assert_equal "Hauler", parsed_body["name"]
      assert_equal ["hardpoint_power_plant"], parsed_body["items"].pluck("slotPath")
    end
  end

  test "GET /public/hangars/:username/vehicles/:vehicle_id/loadouts/:id hands visitors the power presets" do
    @loadout.update!(power_presets: [{name: "Haul", scm: [], nav: [{port_path: "hardpoint_power_plant", pips: 1}]}])

    assert_api_response :get, 200, api_path: SHOW, path_params: path do
      assert_equal [{"name" => "Haul", "scm" => [], "nav" => [{"portPath" => "hardpoint_power_plant", "pips" => 1}]}],
        parsed_body["powerPresets"]
    end
  end

  test "GET /public/hangars/:username/vehicles/:vehicle_id/loadouts/:id/slots names what is fitted" do
    assert_api_response :get, 200, api_path: SLOTS, path_params: path do
      assert_equal "Better Plant", parsed_body.sole.dig("fitted", "name")
    end
  end

  test "GET /public/hangars/:username/vehicles/:vehicle_id/loadouts/:id/slots opens a private hangar to its share token" do
    @user.update!(public_hangar: false)
    token = @user.ensure_hangar_share_token!

    assert_api_response :get, 200, api_path: SLOTS, path_params: path, params: {share: token}
  end

  test "GET /public/hangars/:username/vehicles/:vehicle_id/loadouts/:id returns 403 while the owner has no vehicle overview" do
    Flipper.disable("vehicle_overview")

    assert_api_response :get, 403, api_path: SHOW, path_params: path
  end

  test "GET /public/hangars/:username/vehicles/:vehicle_id/loadouts/:id returns 404 for a hidden ship" do
    @vehicle.update!(public: false)

    assert_api_response :get, 404, api_path: SHOW, path_params: path
  end

  test "GET /public/hangars/:username/vehicles/:vehicle_id/loadouts/:id returns 404 for a loadout its owner keeps private" do
    @loadout.update!(public: false)

    assert_api_response :get, 404, api_path: SHOW, path_params: path
  end

  test "GET /public/hangars/:username/vehicles/:vehicle_id/loadouts/:id/slots returns 404 for a loadout its owner keeps private" do
    @loadout.update!(public: false)

    assert_api_response :get, 404, api_path: SLOTS, path_params: path
  end

  test "GET /public/hangars/:username/vehicles/:vehicle_id/loadouts/:id returns 404 for a linked build" do
    link = @vehicle.vehicle_loadouts.create!(kind: "link", url: "https://www.erkul.games/loadout/abc", public: true)

    assert_api_response :get, 404, api_path: SHOW, path_params: path(loadout: link)
  end

  test "GET /public/hangars/:username/vehicles/:vehicle_id/loadouts/:id/slots returns 404 for a private hangar" do
    @user.update!(public_hangar: false)

    assert_api_response :get, 404, api_path: SLOTS, path_params: path
  end
end
