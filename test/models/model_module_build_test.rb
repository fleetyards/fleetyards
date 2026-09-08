# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: model_module_builds
#
#  id              :uuid             not null, primary key
#  cargo_holds     :string
#  description     :text
#  environment     :string           not null
#  version         :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  model_module_id :uuid             not null
#
# Indexes
#
#  index_model_module_builds_on_environment_and_version  (environment,version)
#  index_model_module_builds_on_model_module_id          (model_module_id)
#  index_model_module_builds_on_module_and_build         (model_module_id,environment,version) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (model_module_id => model_modules.id) ON DELETE => cascade
#
class ModelModuleBuildTest < ActiveSupport::TestCase
  setup do
    @environment = ScData::Source.environment
    @version = ScData::Source.version
  end

  test "a module carries one row per build, not two" do
    model_module = create(:model_module, sc_key: "a_module")
    create(:model_module_build, model_module:, environment: @environment, version: @version)

    duplicate = build(:model_module_build, model_module:, environment: @environment, version: @version)

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :model_module_id
  end

  test "the same module can be described by more than one environment" do
    model_module = create(:model_module, sc_key: "a_module")
    create(:model_module_build, model_module:, environment: "live", version: @version)
    create(:model_module_build, model_module:, environment: "ptu", version: @version)

    assert_equal 2, model_module.builds.count
  end

  test "requires the build it describes" do
    build_row = build(:model_module_build, environment: nil, version: nil)

    assert_not build_row.valid?
    assert_includes build_row.errors.attribute_names, :environment
    assert_includes build_row.errors.attribute_names, :version
  end

  test "goes away with the module it describes" do
    model_module = create(:model_module, sc_key: "a_module")
    build_row = create(:model_module_build, model_module:)

    model_module.destroy!

    assert_not ModelModuleBuild.exists?(build_row.id)
  end

  # --- Reading through the build ---------------------------------------------

  test "#description comes from the build in force" do
    model_module = create(:model_module, sc_key: "a_module", description: "what the column says")
    create(:model_module_build, model_module:, description: "what the build says")

    assert_equal "what the build says", model_module.reload.description
  end

  # An RSI-store module the game files do not name, or one an admin filled in.
  test "#description falls back to the column when no build describes the module" do
    model_module = create(:model_module, description: "curated by hand")

    assert_equal "curated by hand", model_module.reload.description
  end

  # `set_cargo_from_hardpoints` derives `cargo` from `cargo_holds` in a
  # `before_save`. A reader answering from the build would hand it the previous
  # build's value on the second load and store a capacity the module does not
  # have, so this one is recorded on the build and not read through.
  test "#cargo_holds is not read through the build" do
    model_module = create(:model_module, sc_key: "a_module")
    create(:model_module_build, model_module:, cargo_holds: [{"capacity" => 99}])

    model_module.reload.update!(cargo_holds: [{"capacity" => 4}])

    assert_equal [{"capacity" => 4}], model_module.reload.cargo_holds
    assert_equal 4.0, model_module.cargo.to_f,
      "the before_save derives cargo from the column, so a build-answered reader would store 99"
  end

  # --- Which modules a build describes ---------------------------------------

  test ".in_build keeps the modules this build describes" do
    described = create(:model_module, sc_key: "described")
    create(:model_module_build, model_module: described)
    other_build = create(:model_module, sc_key: "only_elsewhere")
    create(:model_module_build, model_module: other_build, environment: "ptu", version: "9.9.9-ptu.1")

    ids = ModelModule.in_build.pluck(:id)

    assert_includes ids, described.id
    assert_not_includes ids, other_build.id
  end

  # The question the whole table exists for: a module only the ptu build ships
  # used to be offered under live as well, with an empty loadout.
  test ".in_build resolves against the source asked for" do
    ptu_only = create(:model_module, sc_key: "new_in_ptu")
    create(:model_module_build, model_module: ptu_only, environment: "ptu", version: "9.9.9-ptu.1")
    create(:model_module_build, model_module: create(:model_module, sc_key: "in_live"))

    assert_not_includes ModelModule.in_build.pluck(:id), ptu_only.id

    ScData::Source.with(ScData::Source.new(environment: "ptu", version: "9.9.9-ptu.1")) do
      assert_includes ModelModule.in_build.pluck(:id), ptu_only.id
    end
  end

  # A module with no sc_key is never described by a build -- the loader walks
  # only keyed ones -- and has to stay offered. These are the RSI-store modules
  # Fleetyards knows about and the game files do not.
  test ".in_build keeps a module the game files never name" do
    store_only = create(:model_module, sc_key: nil)
    create(:model_module_build, model_module: create(:model_module, sc_key: "keyed"))

    assert_includes ModelModule.in_build.pluck(:id), store_only.id
  end

  # The window between this table shipping and its backfill running, asked of the
  # environment rather than of the module for the reason Hardpoint.in_build
  # records: retirement deletes a row and prune_builds drops the older ones.
  test ".in_build keeps everything while the environment has no build rows at all" do
    keyed = create(:model_module, sc_key: "keyed")
    ModelModuleBuild.delete_all

    assert_includes ModelModule.in_build.pluck(:id), keyed.id
  end
end
