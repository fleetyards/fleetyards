# frozen_string_literal: true

require "openapi_helper"

class Api::V1::HardpointsLoadoutOptionsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/hardpoints/{id}/loadout-options" do
    parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, description: "Hardpoint id", required: true

    get("Hardpoint Loadout Options") do
      operationId "hardpointLoadoutOptions"
      tags "Hardpoints"
      produces "application/json"

      response(200, "successful") do
        schema ::V1::Schemas::Loadouts::LoadoutOptionList
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  test "GET /hardpoints/:id/loadout-options lists what fits, with the ports each brings" do
    slot = create(:hardpoint, parent: create(:model), sc_name: "hardpoint_gun_nose", source: :game_files,
      types: %w[Turret], min_size: 3, max_size: 3)
    mount = create(:component, name: "Fits", component_type: "Turret", category: "weapon_mounts", size: "3")
    create(:hardpoint, parent: mount, sc_name: "hardpoint_class_2", source: :game_files,
      types: ["WeaponGun"], min_size: 3, max_size: 3)
    create(:component, name: "Too Big", component_type: "Turret", category: "weapon_mounts", size: "4")
    create(:component, name: "Wrong Type", component_type: "WeaponGun", category: "weapons", size: "3")

    assert_api_response :get, 200, path_params: {id: slot.id} do
      option = parsed_body.sole

      assert_equal "Fits", option.dig("component", "name")
      assert_equal ["hardpoint_class_2"], option["slots"].pluck("name")
    end
  end

  test "GET /hardpoints/:id/loadout-options returns 404 for an unknown hardpoint" do
    assert_api_response :get, 404, path_params: {id: SecureRandom.uuid}
  end
end
