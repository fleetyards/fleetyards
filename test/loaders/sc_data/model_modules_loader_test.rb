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

        assert_equal "flight-ready", model_module.reload.production_status
      end

      # `all` walks every keyed module, so one missing file must not stop the
      # ones after it either.
      test "#all carries on past a module the build does not ship" do
        create(:model_module, sc_key: "not_in_this_build")
        present = create(:model_module, sc_key: "aegs_avenger_nose_s3")
        create(:component, sc_key: "aegs_avenger_thruster_main")

        fixture_loader(::ScData::Loader::ModelModulesLoader).all

        assert_equal "flight-ready", present.reload.production_status
      end
    end
  end
end
