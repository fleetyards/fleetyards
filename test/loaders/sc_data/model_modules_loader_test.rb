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

      # --- Discovery ------------------------------------------------------------

      private def module_slot(model, name: "hardpoint_module", types: ["Module"], tag: "TEST_Ship_Module", stock: nil)
        create(:hardpoint, parent: model, source: :game_files, sc_name: name, types:,
          min_size: 3, max_size: 3, port_tags: [tag], required_tags: [tag], component: stock)
      end

      private def module_part(sc_key, name: nil, component_type: "Module", tag: "TEST_Ship_Module", size: "3", category: "module")
        create(:component, sc_key:, name:, component_type:, category:, size:, tags: [tag], required_tags: [tag],
          version: ::ScData::Source.version)
      end

      private def discover
        ::ScData::Loader::ModelModulesLoader.new.discover_modules
      end

      test "#discover_modules creates a module for each part a ship's module slot takes" do
        model = create(:model)
        module_slot(model)
        module_part("TEST_Ship_Module_CargoPod")

        discover

        created = ModelModule.find_by!(sc_key: "TEST_Ship_Module_CargoPod")
        assert_equal "Ship Module Cargo Pod", created.name
        assert_not created.hidden
        assert_equal [model], created.models.to_a
        assert_equal "hardpoint_module", created.module_hardpoints.sole.slot
      end

      test "#discover_modules links the module an admin or the store already keyed rather than another" do
        model = create(:model)
        module_slot(model)
        module_part("TEST_Ship_Module_CargoPod")
        curated = create(:model_module, sc_key: "test_ship_module_cargopod", name: "Cargo Pod")

        assert_no_difference -> { ModelModule.count } do
          discover
          discover
        end

        assert_equal "Cargo Pod", curated.reload.name
        assert_equal [model], curated.models.to_a
      end

      test "#discover_modules gives the store's keyless module of the ship the key rather than a twin" do
        model = create(:model, name: "Galaxy")
        module_slot(model)
        module_part("TEST_Galaxy_Module_Refinery")
        store = create(:model_module, name: "Refinery Module", sc_key: nil)
        create(:module_hardpoint, model:, model_module: store)

        discover

        assert_equal "TEST_Galaxy_Module_Refinery", store.reload.sc_key
        assert_equal [store], model.modules.reload.to_a
      end

      test "#discover_modules leaves the store's modules alone when several could be the one" do
        model = create(:model, name: "Galaxy")
        module_slot(model)
        module_part("TEST_Galaxy_Module_Refinery")
        2.times { |i| create(:module_hardpoint, model:, model_module: create(:model_module, name: "Refinery Module #{i}", sc_key: nil)) }

        discover

        assert ModelModule.exists?(sc_key: "TEST_Galaxy_Module_Refinery")
        assert_equal 2, ModelModule.where(sc_key: nil).count
      end

      # Components keep their key lowercased, so the name has to come from the
      # item file's spelling.
      test "#discover_modules keys and names a module as the item file spells it" do
        model = create(:model)
        module_slot(model)
        module_part("test_ship_module_cargopod")
        loader = ::ScData::Loader::ModelModulesLoader.new
        loader.stubs(:load_module_data).returns({"key" => "TEST_Ship_Module_CargoPod"})

        loader.discover_modules

        created = ModelModule.sole
        assert_equal "TEST_Ship_Module_CargoPod", created.sc_key
        assert_equal "Ship Module Cargo Pod", created.name
      end

      test "#discover_modules leaves out a part whose tags the slot does not meet" do
        model = create(:model)
        module_slot(model)
        module_part("OTHER_Ship_Module_Cargo", tag: "OTHER_Ship_Module")

        discover

        assert_not ModelModule.exists?(sc_key: "OTHER_Ship_Module_Cargo")
      end

      test "#discover_modules leaves out the empty bay, templates and the record a family is cloned from" do
        model = create(:model)
        module_slot(model)
        module_part("TEST_Ship_Module_Base")
        module_part("TEST_Ship_Module_Template")
        module_part("TEST_Ship_Module")

        discover

        assert_empty ModelModule.where(sc_key: %w[TEST_Ship_Module_Base TEST_Ship_Module_Template TEST_Ship_Module])
      end

      test "#discover_modules leaves out a stub whose ports all take nothing" do
        model = create(:model)
        module_slot(model)
        stub = module_part("TEST_Ship_1C_Module")
        create(:hardpoint, parent: stub, source: :game_files, sc_name: "hardpoint_door_left", min_size: 0, max_size: 0)
        real = module_part("TEST_Ship_Module_1C_CargoPod")
        create(:hardpoint, parent: real, source: :game_files, sc_name: "hardpoint_door_left", min_size: 0, max_size: 1)

        discover

        assert_not ModelModule.exists?(sc_key: "TEST_Ship_1C_Module")
        assert ModelModule.exists?(sc_key: "TEST_Ship_Module_1C_CargoPod")
      end

      # The Hornet's centre bay takes a ball turret as readily as the cargo box.
      test "#discover_modules offers every kind of part a mixed module slot takes" do
        model = create(:model)
        module_slot(model, name: "hardpoint_weapon_center", types: %w[Turret Module], tag: "TEST_Center")
        module_part("TEST_Ship_Cargo_Mod", tag: "TEST_Center")
        module_part("TEST_Ship_Ball_Turret", component_type: "Turret", category: "weapon_mounts", tag: "TEST_Center")

        discover

        assert_equal %w[TEST_Ship_Ball_Turret TEST_Ship_Cargo_Mod], model.modules.pluck(:sc_key).sort
      end

      test "#discover_modules leaves body kits to their own list" do
        model = create(:model)
        module_slot(model, name: "hardpoint_front", tag: "TEST_Ship_Base")
        module_part("TEST_Ship_Cosmetic_Front_A", name: "Bodykit Front", tag: "TEST_Ship_Base", category: "bodykit")

        discover

        assert_empty ModelModule.all
      end

      test "#discover_modules offers only modules in a mixed slot that names no tag" do
        model = create(:model)
        create(:hardpoint, parent: model, source: :game_files, sc_name: "hardpoint_weapon_center",
          types: %w[Turret Module], min_size: 3, max_size: 3)
        create(:component, sc_key: "TEST_Ship_Cargo_Mod", component_type: "Module", category: "module", size: "3",
          version: ::ScData::Source.version)
        create(:component, sc_key: "OTHER_Ship_Ball_Turret", component_type: "Turret", category: "weapon_mounts", size: "3",
          version: ::ScData::Source.version)

        discover

        assert_equal %w[TEST_Ship_Cargo_Mod], model.modules.pluck(:sc_key)
      end

      # The game fits it there, whatever the tags say.
      test "#discover_modules offers the part a slot comes with" do
        model = create(:model)
        stock = module_part("TEST_Ship_Module_Stock", tag: "TEST_Variant_Module")
        module_slot(model, stock:)

        discover

        assert_equal %w[TEST_Ship_Module_Stock], model.modules.pluck(:sc_key)
      end

      test "#discover_modules leaves a slot that takes no module alone" do
        model = create(:model)
        module_slot(model, name: "hardpoint_turret", types: ["Turret"], tag: "TEST_Center")
        module_part("TEST_Ship_Ball_Turret", component_type: "Turret", category: "weapon_mounts", tag: "TEST_Center")

        discover

        assert_empty ModelModule.all
      end

      # --- Names ----------------------------------------------------------------

      private def load_with(model_module, data)
        loader = ::ScData::Loader::ModelModulesLoader.new
        loader.stubs(:load_module_data).returns({"key" => model_module.sc_key}.merge(data))
        loader.load_model_module(model_module)
      end

      test "#load_model_module gives the stand-in name way once the game names the module" do
        model_module = create(:model_module, sc_key: "ARGO_MPUV_Module_1C_CargoPod",
          name: ::ScData::Loader::ModelModulesLoader.fallback_name("ARGO_MPUV_Module_1C_CargoPod"))

        load_with(model_module, "name" => "Argo MPUV Cargo Pod")

        assert_equal "Argo MPUV Cargo Pod", model_module.reload.name
      end

      test "#load_model_module keeps a name an admin chose" do
        model_module = create(:model_module, sc_key: "ARGO_MPUV_Module_1C_CargoPod", name: "Cargo Pod")

        load_with(model_module, "name" => "Argo MPUV Cargo Pod")

        assert_equal "Cargo Pod", model_module.reload.name
      end

      test "#load_model_module leaves a module the game has not named out of flight-ready" do
        model_module = create(:model_module, sc_key: "ARGO_MPUV_Module_1C_CargoPod", production_status: "in-concept")

        load_with(model_module, "name" => nil)

        assert_equal "in-concept", model_module.reload.production_status
      end

      test ".fallback_name drops the manufacturer code and splits the words" do
        assert_equal "MPUV Module 1C Cargo Pod", ::ScData::Loader::ModelModulesLoader.fallback_name("ARGO_MPUV_Module_1C_CargoPod")
      end
    end
  end
end
