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

  test "GET /models/:slug/loadout-preview returns the cargo grids, doors and built-in items" do
    create(:component, sc_key: "misc_prospector_thruster_main", name: "Prospector Main Thruster")
    model = create(:model,
      hardpoint_transforms: {
        "ports" => [
          {"name" => "hardpoint_thruster_main", "position" => [0, 0, 5], "rotation" => [0, 0, 0, 1],
           "editable" => false, "stripped" => false, "hullNode" => "hardpoint_thruster_main", "itemKind" => "thruster",
           "defaultItem" => "misc_prospector_thruster_main"},
          {"name" => "hardpoint_bed", "position" => [1, 0, 0], "rotation" => [0, 0, 0, 1],
           "editable" => false, "hullNode" => "bed_helper", "itemKind" => "furniture"}
        ],
        "cargo_grids" => [
          {"name" => "hardpoint_cargogrid_module_04", "port" => "hardpoint_cargogrid_module_04", "parentPort" => nil,
           "position" => [0, 1, 2], "rotation" => [0, 0, 0, 1], "size" => [5.0, 5.0, 7.5], "dimensions" => [5.0, 7.5, 5.0],
           "scu" => 96, "minItem" => [1.25, 1.25, 1.25], "stripped" => false}
        ]
      },
      holo_doors: {"doors" => [
        {"id" => "hardpoint_door_rear", "kind" => "hatch", "position" => [0, -0.4, 10.6], "duration_s" => 3.0,
         "obb_closed" => {"center" => [0, -0.8, 10.7], "axes" => [[1, 0, 0], [0, 1, 0], [0, 0, 1]], "half_size" => [1.9, 1.5, 1.0]},
         "outline" => {"center" => [0, -0.6, 10.7], "axes" => [[1, 0, 0], [0, 1, 0], [0, 0, 1]], "half_size" => [1.9, 1.0, 0.4]},
         "outlineNodes" => ["door_hardpoint_door_rear_0"], "exterior" => true,
         "datacore" => {"record" => "Door_Ship_Ext"},
         "parts" => [{"object" => "RearDoor", "motion" => {"type" => "slide", "open_matrix" => Array.new(16, 0), "keyframes" => [
           {"t" => 0.0, "translation" => [0, 0, 0], "rotation" => [0, 0, 0, 1]},
           {"t" => 1.0, "translation" => [0, -2.0, 0], "rotation" => [0, 0, 0, 1]}
         ]}}]}
      ]})

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      thruster, bed = parsed_body["ports"]

      assert_equal "hardpoint_thruster_main", thruster["hullNode"]
      assert_equal "thruster", thruster["itemKind"]
      assert_equal "Prospector Main Thruster", thruster["defaultItemName"]
      assert_match(/prospector-main-thruster/, thruster["defaultItemSlug"])
      assert_nil bed["defaultItemName"]
      assert_equal "other", bed["itemKind"]

      grid = parsed_body["cargoGrids"].sole

      assert_equal 96, grid["capacity"]
      assert_equal [5.0, 5.0, 7.5], grid["size"]
      assert_not grid.key?("dimensions")

      door = parsed_body["doors"].sole

      assert_equal "hatch", door["kind"]
      assert_equal 3.0, door["durationS"]
      assert_equal [1.9, 1.5, 1.0], door.dig("bounds", "halfSize")
      assert_equal [1.9, 1.0, 0.4], door.dig("outline", "halfSize")
      assert_equal ["door_hardpoint_door_rear_0"], door["outlineNodes"]
      assert door["exterior"]
      assert_equal [{"part" => 0, "object" => "RearDoor", "keyframes" => [
        {"t" => 0.0, "translation" => [0, 0, 0], "rotation" => [0, 0, 0, 1]},
        {"t" => 1.0, "translation" => [0, -2.0, 0], "rotation" => [0, 0, 0, 1]}
      ]}], door["parts"]
    end
  end

  test "GET /models/:slug/loadout-preview returns the hull of each module the ship takes, with its own ports, grids and doors" do
    galaxy = create(:model, hardpoint_transforms: {
      "ports" => [
        {"name" => "hardpoint_module", "parent" => nil, "position" => [0, 0, 0], "rotation" => [0, 0, 0, 1],
         "editable" => true, "defaultItem" => "rsi_galaxy_module_base", "stripped" => true, "geometry" => false}
      ]
    })
    galaxy.holo_hull.attach(io: File.open(Rails.root.join("test/fixtures/holo/plain.glb")), filename: "flight_holo_hull.glb")
    cargo = create(:model_module, sc_key: "RSI_Galaxy_Module_Cargo")
    create(:module_hardpoint, model: galaxy, model_module: cargo, slot: "hardpoint_module")
    tractor = create(:component, sc_key: "rsi_galaxy_cargo_tractor_turret", name: "Cargo Tractor Turret")

    {"rsi_galaxy_module_base" => [], "rsi_galaxy_module_cargo" => [{
      "name" => "hardpoint_tractor_left", "parent" => nil, "position" => [6.25, 2.5, -8.5], "rotation" => [0, 0, 0, 1],
      "editable" => false, "defaultItem" => tractor.sc_key, "hullNode" => "hardpoint_tractor_left", "itemKind" => "turret"
    }]}.each do |sc_key, ports|
      part = create(:component, sc_key:, category: "module", component_type: "Module")
      part.holo_hull.attach(io: File.open(Rails.root.join("test/fixtures/holo/plain.glb")), filename: "holo_hull.glb")
      part.update!(
        hardpoint_transforms: {"ports" => ports, "cargo_grids" => [{"name" => "grid_#{sc_key}", "port" => nil, "parentPort" => nil,
                                                                    "position" => [-10.1, -0.5, 4.5], "rotation" => [0, 0, 0, 1], "size" => [5, 5, 20], "scu" => 256}]},
        holo_doors: {"doors" => [{"id" => "door_close", "kind" => "door", "duration_s" => 10.0, "parts" => []}]}
      )
    end
    # A module part of another ship, which this one takes no slot for.
    create(:component, sc_key: "rsi_aurora_mk2_module_cargo")
      .holo_hull.attach(io: File.open(Rails.root.join("test/fixtures/holo/plain.glb")), filename: "holo_hull.glb")

    assert_api_response :get, 200, path_params: {slug: galaxy.slug} do
      hulls = parsed_body["moduleHulls"].index_by { |hull| hull["scKey"] }

      assert_equal %w[rsi_galaxy_module_base rsi_galaxy_module_cargo], hulls.keys.sort
      cargo_hull = hulls["rsi_galaxy_module_cargo"]
      assert_match(/holo_hull\.glb/, cargo_hull["holoHullUrl"])
      assert_equal "Cargo Tractor Turret", cargo_hull["ports"].first["defaultItemName"]
      assert_equal 256, cargo_hull["cargoGrids"].first["capacity"]
      assert_equal "door_close", cargo_hull["doors"].first["id"]
    end
  end

  test "GET /models/:slug/loadout-preview lists no ports for a ship without an export" do
    model = create(:model)

    assert_api_response :get, 200, path_params: {slug: model.slug} do
      assert_empty parsed_body["ports"]
      assert_empty parsed_body["items"]
      assert_empty parsed_body["servicingAreas"]
      assert_empty parsed_body["cargoGrids"]
      assert_empty parsed_body["doors"]
      assert_empty parsed_body["moduleHulls"]
      assert_not parsed_body.key?("holoHull")
    end
  end

  test "GET /models/:slug/loadout-preview answers as if there were no export while the feature is off" do
    Flipper.disable("loadout_preview")

    assert_api_response :get, 200, path_params: {slug: @model.slug} do
      assert_empty parsed_body["ports"]
      assert_empty parsed_body["items"]
      assert_empty parsed_body["servicingAreas"]
      assert_empty parsed_body["cargoGrids"]
      assert_empty parsed_body["doors"]
      assert_empty parsed_body["moduleHulls"]
      assert_not parsed_body.key?("holoHull")
    end
  end

  test "GET /models/:slug/loadout-preview returns 404 for an unknown model" do
    assert_api_response :get, 404, path_params: {slug: "unknown-ship"}
  end
end
