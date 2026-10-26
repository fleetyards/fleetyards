# frozen_string_literal: true

require "openapi_helper"

class Api::V1::ModelsLoadoutPreviewTest < ActionDispatch::IntegrationTest
  include OpenapiRuby::Adapters::Minitest::DSL

  openapi_schema :"v1/schema"

  api_path "/models/{slug}/loadout-preview" do
    parameter name: "slug", in: :path, schema: {type: :string}, description: "Model slug", required: true

    get("Model Loadout Preview") do
      operationId "modelLoadoutPreview"
      tags "Models"
      produces "application/json"

      response(200, "successful") do
        schema ::V1::Schemas::Models::LoadoutPreview::ModelLoadoutPreview
      end

      response(404, "not found") do
        schema ::Shared::V1::Schemas::StandardError
      end
    end
  end

  setup do
    Flipper.enable("loadout_preview")

    @model = create(:model, hardpoint_transforms: {
      "entity" => "AEGS_Gladius", "state" => "flight", "frame" => "gltf-y-up", "units" => "m",
      "ports" => [
        {"name" => "hardpoint_gun_nose", "parent" => nil, "helper" => true,
         "position" => [0.0, -1.17, -10.59], "rotation" => [0, 0, 0, 1],
         "flags" => "editable", "editable" => true,
         "types" => [{"type" => "Turret", "subTypes" => "Gun,GunTurret"}],
         "defaultItem" => "mount_gimbal_s3", "stripped" => true},
        {"name" => "hardpoint_class_2", "parent" => "hardpoint_gun_nose", "helper" => true,
         "position" => [0.0, -0.14, 0.0], "rotation" => [0, 0, 0, 1],
         "flags" => "$editable", "editable" => true, "types" => [],
         "defaultItem" => "gats_ballisticgatling_s3", "stripped" => true},
        {"name" => "hardpoint_shield_generator_left", "parent" => nil, "helper" => true,
         "position" => [0.0, 0.49, -4.07], "rotation" => [0, 0, 0, 1],
         "flags" => "editable", "editable" => true, "types" => [{"type" => "Shield", "subTypes" => ""}],
         "defaultItem" => "shld_godi_s01_securehyde_scitem", "geometry" => false, "stripped" => false}
      ]
    })
    @model.holo_hull.attach(io: File.open(Rails.root.join("test/fixtures/holo/plain.glb")), filename: "flight_holo_hull.glb")
  end

  test "GET /models/:slug/loadout-preview returns the hull holo and its ports" do
    assert_api_response :get, 200, path_params: {slug: @model.slug} do
      assert_equal "flight_holo_hull.glb", parsed_body.dig("holoHull", "name")

      nose, gun, shield = parsed_body["ports"]

      assert_equal [0.0, -1.17, -10.59], nose["position"]
      assert_equal "mount_gimbal_s3", nose["defaultItem"]
      assert nose["geometry"]
      assert_equal "hardpoint_gun_nose", gun["parent"]
      assert_equal [{"type" => "Shield", "subTypes" => ""}], shield["types"]
      assert_not shield["geometry"]
      assert_not shield["stripped"]
    end
  end

  test "GET /models/:slug/loadout-preview lists no ports for a ship without an export" do
    model = create(:model)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_empty parsed_body["ports"]
      assert_not parsed_body.key?("holoHull")
    end
  end

  test "GET /models/:slug/loadout-preview answers as if there were no export while the feature is off" do
    Flipper.disable("loadout_preview")

    assert_api_response :get, 200, path_params: {slug: @model.slug} do
      assert_empty parsed_body["ports"]
      assert_not parsed_body.key?("holoHull")
    end
  end

  test "GET /models/:slug/loadout-preview returns 404 for an unknown model" do
    assert_api_response :get, 404, path_params: {slug: "unknown-ship"}
  end
end
