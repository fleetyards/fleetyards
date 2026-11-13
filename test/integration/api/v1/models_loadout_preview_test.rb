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
        {"name" => "BAR1", "parent" => "hardpoint_class_2", "helper" => true,
         "position" => [0.0, -0.423, -0.666], "rotation" => [0, 0, 0, 1],
         "flags" => "", "editable" => false, "types" => [],
         "defaultItem" => "gats_ballisticgatling_barrel_s3", "stripped" => false, "inParentHolo" => true},
        {"name" => "hardpoint_shield_generator_left", "parent" => nil, "helper" => true,
         "position" => [0.0, 0.49, -4.07], "rotation" => [0, 0, 0, 1],
         "flags" => "editable", "editable" => true, "types" => [{"type" => "Shield", "subTypes" => ""}],
         "defaultItem" => "shld_godi_s01_securehyde_scitem", "geometry" => false, "stripped" => false}
      ]
    })
    @gimbal = create(:component, sc_key: "mount_gimbal_s3")
    @gimbal.holo.attach(io: File.open(Rails.root.join("test/fixtures/holo/plain.glb")), filename: "holo.glb")
    create(:component, sc_key: "gats_ballisticgatling_s3")
    create(:component, sc_key: "shld_godi_s01_securehyde_scitem")
      .holo.attach(io: File.open(Rails.root.join("test/fixtures/holo/plain.glb")), filename: "holo.glb")
    @model.holo_hull.attach(io: File.open(Rails.root.join("test/fixtures/holo/plain.glb")), filename: "flight_holo_hull.glb")
  end

  test "GET /models/:slug/loadout-preview returns the hull holo and its ports" do
    assert_api_response :get, 200, path_params: {slug: @model.slug} do
      assert_equal "flight_holo_hull.glb", parsed_body.dig("holoHull", "name")

      nose, gun, barrel, shield = parsed_body["ports"]

      assert_equal [0.0, -1.17, -10.59], nose["position"]
      assert_equal "mount_gimbal_s3", nose["defaultItem"]
      assert nose["geometry"]
      assert_equal "hardpoint_gun_nose", gun["parent"]
      assert_not gun["inParentHolo"]
      assert barrel["inParentHolo"]
      assert_not barrel["stripped"]
      assert_equal [{"type" => "Shield", "subTypes" => ""}], shield["types"]
      assert_not shield["geometry"]
      assert_not shield["stripped"]

      assert_equal %w[mount_gimbal_s3 shld_godi_s01_securehyde_scitem], parsed_body["items"].pluck("scKey").sort
      assert_match(/holo\.glb/, parsed_body["items"].first["holoUrl"])
    end
  end

  test "GET /models/:slug/loadout-preview returns the servicing areas numbered as the ship's page does" do
    hold = "objectcontainers/ships/rsi/galaxy/int_body_rear.socpak"
    deck = "objectcontainers/ships/rsi/galaxy/int_body_front.socpak"
    model = create(:model,
      servicing_areas: [
        {"key" => "#{deck}#Deck", "name" => "Deck", "width" => 8.0, "length" => 10.0, "height" => 4.0},
        {"key" => "#{hold}#RepairZone", "name" => "RepairZone", "width" => 12.0, "length" => 14.0, "height" => 12.0}
      ],
      servicing_area_names: {"#{hold}#RepairZone" => "Rear hangar"},
      hardpoint_transforms: {"ports" => [], "servicing_areas" => [
        {"name" => "Unlisted", "container" => hold, "bone" => "animated_body",
         "position" => [1.0, 2.0, 3.0], "rotation" => [0, 0, 0, 1], "size" => [2.0, 2.0, 2.0]},
        {"name" => "RepairZone", "container" => hold, "bone" => "animated_body",
         "position" => [0.0, 0.84585, 28.20389], "rotation" => [0, 0, 0, 1], "size" => [12.04, 11.97, 14.1]}
      ]})

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      repair, unlisted = parsed_body["servicingAreas"]

      assert_equal "#{hold}#RepairZone", repair["key"]
      assert_equal "Rear hangar", repair["name"]
      assert_equal 2, repair["index"]
      assert_equal [0.0, 0.84585, 28.20389], repair["position"]
      assert_equal [12.04, 11.97, 14.1], repair["size"]
      assert_equal [12.0, 14.0, 12.0], repair.values_at("width", "length", "height")
      assert_nil unlisted["name"]
      assert_equal 3, unlisted["index"]
      assert_equal [2.0, 2.0, 2.0], unlisted.values_at("width", "length", "height")
    end
  end

  test "GET /models/:slug/loadout-preview lists no ports for a ship without an export" do
    model = create(:model)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_empty parsed_body["ports"]
      assert_empty parsed_body["items"]
      assert_empty parsed_body["servicingAreas"]
      assert_not parsed_body.key?("holoHull")
    end
  end

  test "GET /models/:slug/loadout-preview answers as if there were no export while the feature is off" do
    Flipper.disable("loadout_preview")

    assert_api_response :get, 200, path_params: {slug: @model.slug} do
      assert_empty parsed_body["ports"]
      assert_empty parsed_body["items"]
      assert_empty parsed_body["servicingAreas"]
      assert_not parsed_body.key?("holoHull")
    end
  end

  test "GET /models/:slug/loadout-preview returns 404 for an unknown model" do
    assert_api_response :get, 404, path_params: {slug: "unknown-ship"}
  end
end
