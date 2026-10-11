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

      test "#all retires the build and game-file loadout of a model the export dropped" do
        loader = ::ScData::Loader::ModelsLoader.new
        kept = create(:model, :in_game, name: "Kept Test")
        dropped = create(:model, :in_game, name: "Dropped Test")
        kept_port = create(:hardpoint, parent: kept, source: :game_files)
        dropped_port = create(:hardpoint, parent: dropped, source: :game_files)
        matrix = create(:hardpoint, parent: dropped, source: :ship_matrix)
        loader.stubs(:parsed?).returns(false)
        loader.stubs(:parsed?).with(kept).returns(true)
        loader.stubs(:load_model).with(kept).returns(kept.build)

        loader.all

        assert_not_predicate dropped.reload, :in_game?
        assert_not_includes dropped.hardpoints.in_build, dropped_port
        assert Hardpoint.exists?(dropped_port.id), "the row stays, only this build's say goes"
        assert_includes dropped.hardpoints.in_build, matrix
        assert_includes kept.hardpoints.in_build, kept_port
      end

      # Ports are written before the build, so a load that failed in between
      # leaves a ship with ports in the build and no build of its own.
      test "#all retires the ports a failed load left on a model without a build" do
        loader = ::ScData::Loader::ModelsLoader.new
        kept = create(:model, :in_game, name: "Kept Orphan Test")
        create(:hardpoint, parent: kept, source: :game_files)
        orphaned = create(:model, name: "Orphaned Test")
        orphaned_port = create(:hardpoint, parent: orphaned, source: :game_files)
        loader.stubs(:parsed?).returns(false)
        loader.stubs(:parsed?).with(kept).returns(true)
        loader.stubs(:load_model).with(kept).returns(kept.build)

        loader.all

        assert_not_includes orphaned.hardpoints.in_build, orphaned_port
      end

      test "#all retires nothing when the run loaded nothing" do
        loader = ::ScData::Loader::ModelsLoader.new
        model = create(:model, :in_game, name: "Nothing Loaded Test")
        port = create(:hardpoint, parent: model, source: :game_files)
        loader.stubs(:parsed?).returns(false)

        loader.all

        assert_predicate model.reload, :in_game?
        assert_includes model.hardpoints.in_build, port
      end

      test "#one retires the build of a model whose file the build does not ship" do
        loader = ::ScData::Loader::ModelsLoader.new
        model = create(:model, :in_game, name: "Unlinked Test")
        loader.stubs(:load_model_data).returns(nil)

        loader.one(model)

        assert_not_predicate model.reload, :in_game?
      end

      test "#one retires the game-file loadout of a model whose file is missing" do
        loader = ::ScData::Loader::ModelsLoader.new
        model = create(:model, :in_game, name: "Unlinked Loadout Test")
        port = create(:hardpoint, parent: model, source: :game_files)
        nested = create(:hardpoint, parent: port, source: :game_files)
        matrix = create(:hardpoint, parent: model, source: :ship_matrix)
        # Another ship's port keeps the environment in a build; with no build
        # rows at all `in_build` serves every slot.
        create(:hardpoint, source: :game_files)
        loader.stubs(:load_model_data).returns(nil)

        loader.one(model)

        assert_empty HardpointBuild.current.where(hardpoint_id: [port.id, nested.id])
        assert Hardpoint.exists?(port.id), "the rows stay, only this build's say goes"
        assert_includes model.hardpoints.in_build, matrix
        assert_not_includes model.hardpoints.in_build, port
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

      # A ship made from the game files has no mass until this load writes one,
      # and its accelerations are worked out before that.
      test "#load_model derives the accelerations from the mass it is loading" do
        loader = ::ScData::Loader::ModelsLoader.new
        model = create(:model, name: "First Load Test", mass: 0)
        main = create(:component, category: "thrusters", type_data: {"thruster_type" => "Main", "thrust_capacity" => 50_000.0})
        create(:hardpoint, parent: model, component: main)

        loader.stubs(:load_model_data).returns({"mass" => 1000.0, "loadout" => []})
        loader.stubs(:update_loadout)

        loader.load_model(model)

        assert_equal 50.0, model.reload.main_acceleration.to_f
      end

      test "#load_model fills in what the matrix never said about a ship" do
        loader = ::ScData::Loader::ModelsLoader.new
        model = create(:model, name: "Unlisted Test", focus: nil, classification: nil)

        loader.stubs(:load_model_data).returns(
          {
            "mass" => 1000.0,
            "loadout" => [],
            "career" => "Multi-Role",
            "role" => "Medium Freight / Gun Ship",
            "description" => 'Manufacturer: RSI\\nFocus: Medium Freight / Gunship\\n\\nA classic.\\nReimagined.'
          }
        )

        loader.load_model(model)
        model.reload

        assert_equal "Medium Freight / Gun Ship", model.focus
        assert_equal "multi", model.classification
        assert_equal "A classic.\nReimagined.", model.description
      end

      test "#load_model keeps what the matrix or an admin already said" do
        loader = ::ScData::Loader::ModelsLoader.new
        model = create(:model, name: "Listed Test", focus: "Gunship", classification: "combat", description: "Ours.")

        loader.stubs(:load_model_data).returns(
          {
            "mass" => 1000.0,
            "loadout" => [],
            "career" => "Multi-Role",
            "role" => "Medium Freight / Gun Ship",
            "description" => 'Manufacturer: RSI\\nFocus: Medium Freight\\n\\nTheirs.'
          }
        )

        loader.load_model(model)
        model.reload

        assert_equal "Gunship", model.focus
        assert_equal "combat", model.classification
        assert_equal "Ours.", model.description
      end

      test "#load_model fills in nothing the export left as a placeholder" do
        loader = ::ScData::Loader::ModelsLoader.new
        model = create(:model, name: "Placeholder Test", focus: nil, classification: nil)

        loader.stubs(:load_model_data).returns(
          {
            "mass" => 1000.0,
            "loadout" => [],
            "career" => "<= PLACEHOLDER =>",
            "role" => "<= PLACEHOLDER =>",
            "description" => "<-=MISSING=->"
          }
        )

        loader.load_model(model)
        model.reload

        assert_nil model.focus
        assert_nil model.classification
        assert_nil model.description
      end

      test "#load_model fills in nothing from a description that is only its header" do
        loader = ::ScData::Loader::ModelsLoader.new
        model = create(:model, name: "Header Only Test")

        loader.stubs(:load_model_data).returns(
          {"mass" => 1000.0, "loadout" => [], "description" => 'Manufacturer: RSI\\nFocus: Gunship'}
        )

        loader.load_model(model)

        assert_nil model.reload.description
      end

      test "#load_model takes the crew from the build" do
        loader = ::ScData::Loader::ModelsLoader.new
        model = create(:model, name: "Crew Test", crew: 6)

        loader.stubs(:load_model_data).returns({"mass" => 1000.0, "loadout" => [], "min_crew" => "4"})

        build = loader.load_model(model)

        assert_equal 4, build.crew
        assert_equal 4, model.reload.crew
      end

      test "#load_model leaves the crew to the matrix when the export gives none" do
        loader = ::ScData::Loader::ModelsLoader.new
        model = create(:model, name: "No Crew Test", crew: 6)

        loader.stubs(:load_model_data).returns({"mass" => 1000.0, "loadout" => [], "min_crew" => "0"})

        build = loader.load_model(model)

        assert_nil build.crew
        assert_equal 6, model.reload.crew
      end

      test "#load_model leaves the ship's own columns to the default environment" do
        loader = ::ScData::Loader::ModelsLoader.new
        model = create(:model, name: "Ptu Fill Test", focus: nil)
        loader.stubs(:default_environment?).returns(false)

        loader.stubs(:load_model_data).returns(
          {"mass" => 1000.0, "loadout" => [], "role" => "Medium Freight"}
        )

        loader.load_model(model)

        assert_nil model.reload.focus
      end

      test "#load_model sizes a ship by the item sizes ours agrees with" do
        loader = ::ScData::Loader::ModelsLoader.new
        large = create(:model, name: "Size Five Test", size: nil)
        unsure = create(:model, name: "Size Three Test", size: nil)

        loader.stubs(:load_model_data).with(large.sc_data_identifier).returns({"mass" => 1000.0, "loadout" => [], "size" => "5"})
        loader.stubs(:load_model_data).with(unsure.sc_data_identifier).returns({"mass" => 1000.0, "loadout" => [], "size" => "3"})

        loader.load_model(large)
        loader.load_model(unsure)

        assert_equal "large", large.reload.size
        assert_nil unsure.reload.size, "3 is a small ship as often as a medium one"
      end

      test "#load_model classifies and sizes a ground vehicle as one whatever its career" do
        loader = ::ScData::Loader::ModelsLoader.new
        model = create(:model, name: "Ground Career Test", classification: nil, size: nil)

        loader.stubs(:load_model_data).returns(
          {"mass" => 1000.0, "loadout" => [], "ground" => true, "career" => "Combat"}
        )

        loader.load_model(model)

        model.reload

        assert_equal "ground", model.classification
        assert_equal "vehicle", model.size
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

      # A hover bike, and the third ship authored with its length on z. Left on the
      # default it came out 1.45 m long and 5.15 m tall, which is a bike stood on
      # its end -- and both columns agreed on it, because both come from the same
      # bounding box.
      # Both keys, because the Kue is a separate entry and a typo in it would
      # restore the bad dimensions for that one variant without failing anything.
      {"Nox" => "xian_nox", "Nox Kue" => "xian_nox_kue"}.each do |name, key|
        test "#load_model uses the curated order for the #{name}" do
          loader = ::ScData::Loader::ModelsLoader.new
          model = create(:model, name:, sc_key: key)

          loader.stubs(:load_model_data).returns(
            {"mass" => 1000.0, "loadout" => [], "metrics" => {"x" => 1.32, "y" => 1.45, "z" => 5.15}}
          )

          loader.load_model(model)
          model.reload

          assert_in_delta 5.15, model.sc_length.to_f
          assert_in_delta 1.32, model.sc_beam.to_f
          assert_in_delta 1.45, model.sc_height.to_f
        end
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
        assert_equal 12.0, model.ground_deceleration.to_f
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
