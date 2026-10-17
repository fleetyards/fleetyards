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

      parameter name: "stockId", in: :query, required: false,
        schema: {type: :string, format: :uuid},
        description: "What the slot came with, which a port inside a part does not know itself"
      parameter name: "modelSlug", in: :query, required: false,
        schema: {type: :string},
        description: "The ship the slot is on, whose tags a part may demand"

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

  test "GET /hardpoints/:id/loadout-options offers a part the game files repeat once" do
    slot = create(:hardpoint, parent: create(:model), sc_name: "hardpoint_shield", source: :game_files,
      types: %w[Shield], min_size: 1, max_size: 1)
    create(:component, name: "AllStop", sc_key: "shld_godi_s01_allstop_scitem", component_type: "Shield",
      category: "shieldgenerator", size: "1", grade: "3", type_data: {max_health: 3168})
    create(:component, name: "AllStop", sc_key: "shld_godi_s01_allstop_scitem_resistgasclouds", component_type: "Shield",
      category: "shieldgenerator", size: "1", grade: "3", type_data: {max_health: 3168})

    assert_api_response :get, 200, path_params: {id: slot.id} do
      assert_equal ["AllStop"], parsed_body.map { |option| option.dig("component", "name") }
    end
  end

  test "GET /hardpoints/:id/loadout-options offers guns where the slot came with a bare gun" do
    mount = create(:component, component_type: "Turret", category: "weapon_mounts", size: "4")
    port = create(:hardpoint, parent: mount, sc_name: "hardpoint_weapon", source: :game_files,
      types: %w[Turret WeaponGun], min_size: 3, max_size: 3)
    gun = create(:component, name: "Gun", component_type: "WeaponGun", category: "weapons", size: "3")

    assert_api_response :get, 200, path_params: {id: port.id}, params: {stockId: gun.id} do
      assert_includes parsed_body.map { |option| option.dig("component", "name") }, "Gun"
    end
  end

  test "GET /hardpoints/:id/loadout-options leaves out parts that demand another ship's tag" do
    model = create(:model)
    slot = create(:hardpoint, parent: model, sc_name: "hardpoint_gun", source: :game_files,
      types: %w[WeaponGun], min_size: 2, max_size: 2)
    create(:component, name: "Plain Gun", component_type: "WeaponGun", category: "weapons", size: "2")
    create(:component, name: "Taurus Beam", component_type: "WeaponGun", category: "weapons", size: "2",
      required_tags: ["Taurus_TractorBeam"])

    assert_api_response :get, 200, path_params: {id: slot.id}, params: {modelSlug: model.slug} do
      assert_equal ["Plain Gun"], parsed_body.map { |option| option.dig("component", "name") }
    end
  end

  test "GET /hardpoints/:id/loadout-options returns 404 for an unknown ship" do
    slot = create(:hardpoint, parent: create(:model), sc_name: "hardpoint_gun", source: :game_files,
      types: %w[WeaponGun], min_size: 2, max_size: 2)

    assert_api_response :get, 404, path_params: {id: slot.id}, params: {modelSlug: "no-such-ship"}
  end

  test "GET /hardpoints/:id/loadout-options returns 404 for an unknown hardpoint" do
    assert_api_response :get, 404, path_params: {id: SecureRandom.uuid}
  end
end
