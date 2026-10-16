# frozen_string_literal: true

require "test_helper"
require "support/sc_data_fixture_tree"

module ScData
  module Loader
    class ModelModulesLoaderTest < ActiveSupport::TestCase
      include ScDataFixtureTree

      # `load_item` answers nil for a path the tree does not carry, and
      # `resolve_loadout` indexes it straight away -- so a build that stopped
      # shipping a module's item file used to raise `NoMethodError` on nil. And
      # because the whole of `BaseLoader.all` runs in one job, that took every
      # loader after this one with it.
      #
      # Found by reading during the first real PTU load rather than by running
      # it: all six module keys were present in `4.10.1-ptu.12578875`, so nothing
      # fired.
      test "#load_model_module leaves a module alone when the build ships no item file for it" do
        model_module = create(:model_module, sc_key: "not_in_this_build")

        assert_nothing_raised do
          empty_tree_loader(::ScData::Loader::ModelModulesLoader).load_model_module(model_module)
        end
      end

      # The module keeps what the last build gave it, which is the only answer
      # available while `ModelModule` has no build table of its own.
      test "#load_model_module keeps the loadout a previous build wrote" do
        model_module = create(:model_module, sc_key: "not_in_this_build")
        kept = create(:hardpoint, parent: model_module, sc_name: "kept", source: :game_files)

        empty_tree_loader(::ScData::Loader::ModelModulesLoader).load_model_module(model_module)

        assert Hardpoint.exists?(kept.id)
      end

      # And the guard has to be the missing file, not every module: one whose
      # file is there still loads.
      test "#load_model_module writes the loadout for a module the build does ship" do
        create(:component, sc_key: "aegs_avenger_thruster_main")
        model_module = create(:model_module, sc_key: "aegs_avenger_nose_s3")

        fixture_loader(::ScData::Loader::ModelModulesLoader).load_model_module(model_module)

        # The build row rather than `production_status`: that follows the live
        # build now, and the fixture tree is not the default source.
        assert_not_nil model_module.builds.sole
      end

      # Some module items ship with no ports at all, and still carry a name and
      # a description to load.
      test "#load_model_module loads a module whose item has no loadout" do
        model_module = create(:model_module, sc_key: "RSI_Apollo_Module_Left_Tier_2", description: nil)

        assert_nothing_raised do
          fixture_loader(::ScData::Loader::ModelModulesLoader).load_model_module(model_module)
        end

        assert_equal "This module contains 2x Tier 2 medical beds.", model_module.reload.description
        assert_not_nil model_module.builds.sole
      end

      # Its rooms are what tell it apart: the beds they hold, by tier.
      test "#load_model_module loads the medical beds a module's rooms hold" do
        model_module = create(:model_module, sc_key: "RSI_Apollo_Module_Left_Tier_2")

        fixture_loader(::ScData::Loader::ModelModulesLoader).load_model_module(model_module)

        expected = {"tiers" => [{"tier" => 2, "name" => "Clinic", "beds" => 2}], "respawn_beds" => 2}
        assert_equal expected, model_module.reload.medical_beds
        assert_equal expected, model_module.builds.sole.medical_beds
      end

      test "#load_model_module clears beds a build no longer places, and writes none for a module without" do
        emptied = create(:model_module, sc_key: "aegs_avenger_nose_s3", medical_beds: {"tiers" => [], "respawn_beds" => 1})
        never = create(:model_module, sc_key: "aegs_avenger_nose_s3")
        create(:component, sc_key: "aegs_avenger_thruster_main")

        fixture_loader(::ScData::Loader::ModelModulesLoader).load_model_module(emptied)
        fixture_loader(::ScData::Loader::ModelModulesLoader).load_model_module(never)

        assert_nil emptied.reload.read_attribute(:medical_beds)
        assert_nil emptied.builds.sole.medical_beds
        assert_nil never.reload.read_attribute(:medical_beds)
      end

      test "#load_model_module clears beds from the build it reloads once they are gone" do
        model_module = create(:model_module, sc_key: "aegs_avenger_nose_s3")
        create(:component, sc_key: "aegs_avenger_thruster_main")
        model_module.builds.create!(environment: fixture_source.environment, version: fixture_source.version,
          medical_beds: {"tiers" => [], "respawn_beds" => 1})
        model_module.update_columns(medical_beds: {"tiers" => [], "respawn_beds" => 1}.to_yaml)

        ::ScData::Source.with(fixture_source) do
          fixture_loader(::ScData::Loader::ModelModulesLoader).load_model_module(model_module)
        end

        assert_nil model_module.builds.sole.reload.medical_beds
      end

      # No ports is an empty loadout, not a skipped one: what an earlier load of
      # the same build gave the module is retired.
      test "#load_model_module retires the slots of a module whose item has no loadout" do
        model_module = create(:model_module, sc_key: "RSI_Apollo_Module_Left_Tier_2")
        stale = create(:hardpoint, parent: model_module, sc_name: "stale", source: :game_files, with_build: false)
        stale.builds.create!(environment: fixture_source.environment, version: fixture_source.version)

        fixture_loader(::ScData::Loader::ModelModulesLoader).load_model_module(model_module)

        assert Hardpoint.exists?(stale.id)
        assert_empty HardpointBuild.current(fixture_source).where(hardpoint: stale)
      end

      # --- Builds -------------------------------------------------------------

      test "#load_model_module writes a build row for the source it is loading" do
        create(:component, sc_key: "aegs_avenger_thruster_main")
        model_module = create(:model_module, sc_key: "aegs_avenger_nose_s3")

        fixture_loader(::ScData::Loader::ModelModulesLoader).load_model_module(model_module)

        build_row = model_module.builds.sole
        assert_equal "test", build_row.environment
        assert_equal ::ScData::Source.version, build_row.version
      end

      # The question the table exists for. A module row is shared by every
      # source -- created by ModulesImporter or by an admin, never by a load --
      # so before this, one only the ptu build shipped was offered under live as
      # well, with an empty loadout.
      test "#all retires the build row of a module this build no longer names" do
        create(:component, sc_key: "aegs_avenger_thruster_main")
        gone = create(:model_module, sc_key: "not_in_this_build")
        create(:model_module_build, model_module: gone, environment: "test",
          version: ::ScData::Source.version)
        create(:model_module, sc_key: "aegs_avenger_nose_s3")

        fixture_loader(::ScData::Loader::ModelModulesLoader).all

        assert_empty gone.reload.builds, "the row for this build goes"
        assert ModelModule.exists?(gone.id), "the module itself stays"
      end

      test "#all leaves another environment's build row alone" do
        create(:component, sc_key: "aegs_avenger_thruster_main")
        gone = create(:model_module, sc_key: "not_in_this_build")
        elsewhere = create(:model_module_build, model_module: gone, environment: "ptu",
          version: "9.9.9-ptu.1")
        create(:model_module, sc_key: "aegs_avenger_nose_s3")

        fixture_loader(::ScData::Loader::ModelModulesLoader).all

        assert ModelModuleBuild.exists?(elsewhere.id)
      end

      # --- production_status ---------------------------------------------------

      # Curated until the live game ships it, automatic afterwards. The fixture
      # tree is the "test" environment, so it stands in for live here.
      private def loading_live
        version = ::ScData::Source.version

        Rails.configuration.stubs(:sc_data).returns({sources: {test: version}, default: "test"})
      end

      test "#load_model_module marks a module flight-ready once the live build ships it" do
        loading_live
        create(:component, sc_key: "aegs_avenger_thruster_main")
        model_module = create(:model_module, sc_key: "aegs_avenger_nose_s3", production_status: "in-concept")

        fixture_loader(::ScData::Loader::ModelModulesLoader).load_model_module(model_module)

        assert_equal "flight-ready", model_module.reload.production_status
      end

      # A ptu build saying so is not the game saying so. The status is asked of
      # the default source, not of the one being loaded, so a ptu load of a
      # module live does not have leaves the curated value alone.
      test "#load_model_module leaves the status alone when only a preview build ships it" do
        version = ::ScData::Source.version
        Rails.configuration.stubs(:sc_data).returns({
          sources: {live: "9.9.9-live.1", test: version}, default: "live"
        })
        create(:component, sc_key: "aegs_avenger_thruster_main")
        model_module = create(:model_module, sc_key: "aegs_avenger_nose_s3", production_status: "in-concept")

        fixture_loader(::ScData::Loader::ModelModulesLoader).load_model_module(model_module)

        assert_equal "in-concept", model_module.reload.production_status,
          "the test tree is not the default source here, so it stands in for ptu"
      end

      # And it does not lag a build behind: the row this load is about to write
      # counts, or the status would only flip on the *next* live load.
      test "#load_model_module does not wait for a second live load" do
        loading_live
        create(:component, sc_key: "aegs_avenger_thruster_main")
        model_module = create(:model_module, sc_key: "aegs_avenger_nose_s3", production_status: "in-concept")

        assert_empty model_module.builds, "no build row exists when the status is decided"

        fixture_loader(::ScData::Loader::ModelModulesLoader).load_model_module(model_module)

        assert_equal "flight-ready", model_module.reload.production_status
      end

      # `all` walks every keyed module, so one missing file must not stop the
      # ones after it either.
      test "#all carries on past a module the build does not ship" do
        create(:model_module, sc_key: "not_in_this_build")
        present = create(:model_module, sc_key: "aegs_avenger_nose_s3")
        create(:component, sc_key: "aegs_avenger_thruster_main")

        fixture_loader(::ScData::Loader::ModelModulesLoader).all

        assert_not_nil present.reload.builds.sole, "the module after the missing one still loaded"
      end
    end
  end
end
