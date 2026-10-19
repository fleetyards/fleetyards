# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ModelsLoadoutSlotsTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/{slug}/loadout-slots" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Model slug", required: true

    get("Model Loadout Slots") do
      operationId "modelLoadoutSlots"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema ::V1::Schemas::Loadouts::LoadoutSlotList
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    @model = create(:model)
    @gun = create(:component, name: "Stock Gun", component_type: "WeaponGun", category: "weapons", size: "3")
    mount = create(:component, name: "Stock Mount", component_type: "Turret", category: "weapon_mounts", size: "3")
    create(:hardpoint, parent: mount, sc_name: "hardpoint_class_2", source: :game_files,
      types: ["WeaponGun"], min_size: 2, max_size: 3)

    nose = create(:hardpoint, parent: @model, sc_name: "hardpoint_gun_nose", source: :game_files,
      types: %w[Turret WeaponGun], min_size: 3, max_size: 3, component: mount, flags: ["uneditable"])
    create(:hardpoint, parent: nose, sc_name: "hardpoint_class_2", source: :game_files, component: @gun)
    create(:hardpoint, parent: @model, sc_name: "hardpoint_door", source: :game_files,
      component: create(:component, component_type: "Door", category: "doors", size: "1"))
  end

  test "GET /models/:slug/loadout-slots returns the slots a player fits, with what sits below" do
    assert_api_response :get, 200, path_params: {slug: @model.slug} do
      nose = parsed_body.sole

      assert_equal "hardpoint_gun_nose", nose["name"]
      assert_equal "Stock Mount", nose.dig("stock", "name")
      assert_not nose["editable"]

      gun_port = nose["slots"].sole
      assert_equal ["WeaponGun"], gun_port["types"]
      assert_equal [2, 3], [gun_port["minSize"], gun_port["maxSize"]]
      assert_equal "Stock Gun", gun_port.dig("stock", "name")
      assert gun_port["editable"]
    end
  end

  test "GET /models/:slug/loadout-slots says which parts a recipe makes" do
    create(:blueprint, craftable: @gun)

    assert_api_response :get, 200, path_params: {slug: @model.slug} do
      nose = parsed_body.sole

      assert nose.dig("slots", 0, "stock", "craftable")
      assert_equal false, nose.dig("stock", "craftable")
    end
  end

  test "GET /models/:slug/loadout-slots returns 404 for unknown model" do
    assert_api_response :get, 404, path_params: {slug: "unknown-model"}
  end
end
