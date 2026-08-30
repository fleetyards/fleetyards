# frozen_string_literal: true

require "test_helper"
require "support/hangar_import_fixtures"

module ScData
  module Loader
    class ModelsLoaderTest < ActiveSupport::TestCase
      include HangarImportFixtures

      setup do
        clean_loader_tables
      end

      test "#one loads data from game files" do
        loader = ::ScData::Loader::ModelsLoader.new
        manufacturer = create(:manufacturer, name: "Roberts Space Industries", slug: "rsi", code: "RSI")
        model = create(:model, :in_game, name: "Constellation Andromeda", manufacturer: manufacturer)

        assert_difference -> { Hardpoint.where(parent: model).count }, 95 do
          loader.one(model)
        end
      end

      test "#load_model persists the parsed cross section signature" do
        loader = ::ScData::Loader::ModelsLoader.new
        model = create(:model, :in_game, name: "Cross Section Test")
        cross_section = {"x" => 12.5, "y" => 34.0, "z" => 56.25}

        loader.stubs(:load_model_data).returns(
          {"mass" => 1000.0, "loadout" => [], "signature_cross_section" => cross_section}
        )

        loader.load_model(model)

        assert_equal cross_section, model.reload.signature_cross_section
      end

      # The export's bounding box carries three correct magnitudes but no
      # consistent convention for which axis is which, so a handful of ships need
      # their own order. Read off the orthographic renders rather than the ship
      # matrix, which is itself wrong for several of them.
      test "#load_model reads the dimensions off y, x, z by default" do
        loader = ::ScData::Loader::ModelsLoader.new
        model = create(:model, name: "Default Order", sc_key: "test_default_order")

        loader.stubs(:load_model_data).returns(
          {"mass" => 1000.0, "loadout" => [], "metrics" => {"x" => 39.5, "y" => 111.5, "z" => 13.4}}
        )

        loader.load_model(model)
        model.reload

        assert_in_delta 111.5, model.sc_length.to_f
        assert_in_delta 39.5, model.sc_beam.to_f
        assert_in_delta 13.4, model.sc_height.to_f
      end

      # Its length sits on z: 111.5 m, which the default order would have read as
      # its height.
      test "#load_model uses the curated order for the Caterpillar" do
        loader = ::ScData::Loader::ModelsLoader.new
        model = create(:model, name: "Caterpillar", sc_key: "drak_caterpillar")

        loader.stubs(:load_model_data).returns(
          {"mass" => 1000.0, "loadout" => [], "metrics" => {"x" => 39.5, "y" => 13.4, "z" => 111.5}}
        )

        loader.load_model(model)
        model.reload

        assert_in_delta 111.5, model.sc_length.to_f
        assert_in_delta 39.5, model.sc_beam.to_f
        assert_in_delta 13.4, model.sc_height.to_f
      end

      # The Cyclone is the case that shows why the renders decide this and not the
      # matrix: the matrix has it 6.0 m long and 8.8 m wide, and the render says
      # the opposite. So the curated order deliberately disagrees with the matrix.
      test "#load_model uses the curated order for the Cyclone, against the matrix" do
        loader = ::ScData::Loader::ModelsLoader.new
        model = create(:model, name: "Cyclone", sc_key: "tmbl_cyclone", length: 6.0, beam: 8.8, height: 3.5)

        loader.stubs(:load_model_data).returns(
          {"mass" => 1000.0, "loadout" => [], "metrics" => {"x" => 8.8, "y" => 6.0, "z" => 3.5}}
        )

        loader.load_model(model)
        model.reload

        assert_in_delta 8.8, model.sc_length.to_f
        assert_in_delta 6.0, model.sc_beam.to_f
        assert_in_delta 3.5, model.sc_height.to_f
      end

      test "#load_model survives an export with no metrics at all" do
        loader = ::ScData::Loader::ModelsLoader.new
        model = create(:model, name: "No Metrics", sc_key: "test_no_metrics")

        loader.stubs(:load_model_data).returns({"mass" => 1000.0, "loadout" => []})

        loader.load_model(model)
        model.reload

        assert_nil model.sc_length
        assert_nil model.sc_beam
        assert_nil model.sc_height
      end

      test "#load_model persists the parsed ground speeds" do
        loader = ::ScData::Loader::ModelsLoader.new
        model = create(:model, :in_game, name: "Ground Speed Test")

        loader.stubs(:load_model_data).returns(
          {
            "mass" => 1000.0,
            "loadout" => [],
            "speeds" => {
              "max" => 24.0,
              "reverse" => 12.0,
              "acceleration" => 8.0,
              "decceleration" => 12.0
            }
          }
        )

        loader.load_model(model)
        model.reload

        assert_equal 24.0, model.ground_max_speed.to_f
        assert_equal 12.0, model.ground_reverse_speed.to_f
        assert_equal 8.0, model.ground_acceleration.to_f
        assert_equal 12.0, model.ground_decceleration.to_f
      end

      test "#load_model keeps the ground speeds a vehicle does not declare" do
        loader = ::ScData::Loader::ModelsLoader.new
        model = create(:model, :in_game, name: "Wheel Cap Test", ground_reverse_speed: 9.0)

        loader.stubs(:load_model_data).returns(
          {"mass" => 1000.0, "loadout" => [], "speeds" => {"max" => 36.0}}
        )

        loader.load_model(model)
        model.reload

        assert_equal 36.0, model.ground_max_speed.to_f
        assert_equal 9.0, model.ground_reverse_speed.to_f
      end

      test "#load_model persists the personal inventory the container declares" do
        loader = ::ScData::Loader::ModelsLoader.new
        model = create(:model, :in_game, name: "Personal Inventory Test")

        loader.stubs(:load_model_data).returns(
          {
            "mass" => 1000.0,
            "loadout" => [],
            "inventory_container_ref" => "74fd8018-4e99-4dd6-a968-4b9c948aa759"
          }
        )
        loader.stubs(:personal_storage_index).returns(
          {"74fd8018-4e99-4dd6-a968-4b9c948aa759" => 3.43}
        )

        loader.load_model(model)

        assert_equal 3.43, model.reload.personal_inventory.to_f
      end

      test "#load_model keeps the personal inventory when the container is unknown" do
        loader = ::ScData::Loader::ModelsLoader.new
        model = create(:model, :in_game, name: "Unknown Container Test", personal_inventory: 1.72)

        loader.stubs(:load_model_data).returns(
          {"mass" => 1000.0, "loadout" => [], "inventory_container_ref" => "missing-ref"}
        )
        loader.stubs(:personal_storage_index).returns({})

        loader.load_model(model)

        assert_equal 1.72, model.reload.personal_inventory.to_f
      end
    end
  end
end
