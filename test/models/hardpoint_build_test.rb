# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: hardpoint_builds
#
#  id            :uuid             not null, primary key
#  category      :integer
#  environment   :string           not null
#  flags         :string
#  group         :integer
#  group_key     :string
#  max_size      :integer
#  min_size      :integer
#  port_tags     :string
#  required_tags :string
#  types         :string
#  version       :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  component_id  :uuid
#  hardpoint_id  :uuid             not null
#
# Indexes
#
#  index_hardpoint_builds_on_component_id             (component_id)
#  index_hardpoint_builds_on_environment_and_version  (environment,version)
#  index_hardpoint_builds_on_hardpoint_and_build      (hardpoint_id,environment,version) UNIQUE
#  index_hardpoint_builds_on_hardpoint_id             (hardpoint_id)
#
# Foreign Keys
#
#  fk_rails_...  (hardpoint_id => hardpoints.id) ON DELETE => cascade
#
class HardpointBuildTest < ActiveSupport::TestCase
  setup do
    @environment = ScData::Source.environment
    @version = ScData::Source.version
  end

  test "a slot carries one row per build, not two" do
    hardpoint = create(:hardpoint, :without_build, source: :game_files)
    create(:hardpoint_build, hardpoint:, environment: @environment, version: @version)

    duplicate = build(:hardpoint_build, hardpoint:, environment: @environment, version: @version)

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :hardpoint_id
  end

  test "a later build of the same environment sits beside the earlier one" do
    hardpoint = create(:hardpoint, :without_build, source: :game_files)
    create(:hardpoint_build, hardpoint:, environment: @environment, version: "0.0.1-live.1")
    create(:hardpoint_build, hardpoint:, environment: @environment, version: "0.0.2-live.2")

    assert_equal 2, hardpoint.builds.count
  end

  test "the same slot can be described by more than one environment" do
    hardpoint = create(:hardpoint, :without_build, source: :game_files)
    create(:hardpoint_build, hardpoint:, environment: "live", version: @version)
    create(:hardpoint_build, hardpoint:, environment: "ptu", version: @version)

    assert_equal 2, hardpoint.builds.count
  end

  test "requires the build it describes" do
    build_row = build(:hardpoint_build, environment: nil, version: nil)

    assert_not build_row.valid?
    assert_includes build_row.errors.attribute_names, :environment
    assert_includes build_row.errors.attribute_names, :version
  end

  # --- Which build is in force -----------------------------------------------

  test "#build resolves the row for the source in force and nothing else" do
    hardpoint = create(:hardpoint, :without_build, source: :game_files)
    live = create(:hardpoint_build, hardpoint:, environment: "live", version: "1.0.0-live.1")
    ptu = create(:hardpoint_build, hardpoint:, environment: "ptu", version: "1.0.1-ptu.2")

    ScData::Source.with(ScData::Source.new(environment: "live", version: "1.0.0-live.1")) do
      assert_equal live, hardpoint.reload.build
    end

    ScData::Source.with(ScData::Source.new(environment: "ptu", version: "1.0.1-ptu.2")) do
      assert_equal ptu, hardpoint.reload.build
    end
  end

  # A slot the build does not describe has no row, which is what replaces the
  # destroy in `persist_loadout`. So "no build" has to be a clean nil rather than
  # some other environment's row.
  test "#build is nil for a source that does not describe the slot" do
    hardpoint = create(:hardpoint, :without_build, source: :game_files)
    create(:hardpoint_build, hardpoint:, environment: "live", version: "1.0.0-live.1")

    ScData::Source.with(ScData::Source.new(environment: "ptu", version: "1.0.1-ptu.2")) do
      assert_nil hardpoint.reload.build
    end
  end

  test ".retained_versions keeps the newest builds of one environment, oldest first" do
    hardpoint = create(:hardpoint, :without_build, source: :game_files)

    %w[0.0.1-live.1 0.0.2-live.2 0.0.3-live.3 0.0.4-live.4].each_with_index do |version, index|
      create(:hardpoint_build, hardpoint:, environment: "live", version:,
        created_at: index.days.ago(Time.zone.parse("2026-09-07")))
    end

    retained = HardpointBuild.retained_versions("live")

    assert_equal 3, retained.size
    assert_not_includes retained, "0.0.4-live.4", "the oldest by first appearance drops out"
  end

  # --- The enums are shared, not restated ------------------------------------

  # `group` and `category` derive from the installed component, so they move to
  # the build row -- and a build holding 40 has to read as the same thing the
  # slot's own column does. Restating a 30-entry map is how that drifts, so both
  # models take it from one constant and this is the guard.
  test "reads the same group and category maps as the slot" do
    assert_equal Hardpoint.groups, HardpointBuild.groups
    assert_equal Hardpoint.categories, HardpointBuild.categories
  end

  test "round-trips a serialized tag list the way the slot does" do
    build_row = create(:hardpoint_build,
      types: ["MissileLauncher", "BombLauncher"],
      port_tags: ["Eclipse_BombRack"],
      required_tags: ["Eclipse_BombRack"],
      flags: ["editable", "swaponly"])

    build_row.reload

    assert_equal ["MissileLauncher", "BombLauncher"], build_row.types
    assert_equal ["Eclipse_BombRack"], build_row.port_tags
    assert_equal ["Eclipse_BombRack"], build_row.required_tags
    assert_equal ["editable", "swaponly"], build_row.flags
  end

  # --- The slot's natural key ------------------------------------------------

  # Once build rows hang off a slot, "the slot called X on this parent" has to
  # mean one row. The loader has always kept that with `find_or_initialize_by`
  # and nothing enforced it.
  test "refuses a second game_files slot of the same name on one parent" do
    model = create(:model)
    create(:hardpoint, :without_build, parent: model, sc_name: "hardpoint_power", source: :game_files)

    assert_raises(ActiveRecord::RecordNotUnique) do
      create(:hardpoint, :without_build, parent: model, sc_name: "hardpoint_power", source: :game_files)
    end
  end

  # The matrix half is not a set of named ports: it repeats names by design, and
  # a ship carries 32 rows called "Maneuvering Thruster". Measured on the real
  # table before the index was written -- unscoped it is impossible, 1,222
  # duplicate groups and 2,406 excess rows, every one of them ship_matrix.
  test "allows a repeated ship_matrix slot name, which the matrix relies on" do
    model = create(:model)
    create(:hardpoint, :without_build, parent: model, sc_name: "Maneuvering Thruster", source: :ship_matrix)

    assert_nothing_raised do
      create(:hardpoint, :without_build, parent: model, sc_name: "Maneuvering Thruster", source: :ship_matrix)
    end
  end

  test "does not collide a game_files slot with a matrix slot of the same name" do
    model = create(:model)
    create(:hardpoint, :without_build, parent: model, sc_name: "shared_name", source: :ship_matrix)

    assert_nothing_raised do
      create(:hardpoint, :without_build, parent: model, sc_name: "shared_name", source: :game_files)
    end
  end

  # --- Reading through the build ---------------------------------------------

  # An object to read from rather than reader overrides in the style of
  # Component, because Hardpoint derives group, category and group_key in a
  # before_validation and the enum predicates those use read the attribute
  # rather than the reader -- so an override would leave `group` and
  # `thruster_group?` disagreeing.
  test "#facts is the build row when one describes the slot" do
    hardpoint = create(:hardpoint, :without_build, source: :game_files)
    build_row = create(:hardpoint_build, hardpoint:)

    assert_equal build_row, hardpoint.reload.facts
  end

  # The matrix half comes from no build, and its facts live only on the row.
  test "#facts is the slot itself when no build describes it" do
    hardpoint = create(:hardpoint, :without_build, source: :ship_matrix)

    assert_equal hardpoint, hardpoint.facts
  end

  # A build row's nil is an answer, not a gap: an empty port in this build has
  # to read as empty rather than falling through to the column.
  test "#facts answers with the build's emptiness rather than the column's value" do
    hardpoint = create(:hardpoint, :without_build, source: :game_files,
      component: create(:component))
    create(:hardpoint_build, hardpoint:, component: nil)

    assert_nil hardpoint.reload.facts.component
    assert_not_nil hardpoint.component, "the column still holds what it held"
  end

  test "#retired? is true only for a game-files slot no build describes" do
    assert_predicate create(:hardpoint, :without_build, source: :game_files), :retired?
    assert_not_predicate create(:hardpoint, source: :game_files), :retired?
    assert_not_predicate create(:hardpoint, :without_build, source: :ship_matrix), :retired?
  end

  test ".in_build keeps the slots this build describes and the whole matrix half" do
    described = create(:hardpoint, source: :game_files)
    retired = create(:hardpoint, :without_build, source: :game_files)
    matrix = create(:hardpoint, :without_build, source: :ship_matrix)

    ids = Hardpoint.in_build.pluck(:id)

    assert_includes ids, described.id
    assert_includes ids, matrix.id
    assert_not_includes ids, retired.id
  end

  # The deploy this exists for: the build table and the build-resolved reads can
  # ship before the backfill task has run, and without this clause every
  # game-file slot drops out of the API at once -- 22,561 of them, leaving only
  # the 4,974 matrix ones, which for most ships is nothing.
  test ".in_build keeps everything while the environment has no build rows at all" do
    slot = create(:hardpoint, :without_build, source: :game_files)
    HardpointBuild.delete_all

    assert_includes Hardpoint.in_build.pluck(:id), slot.id
  end

  # Asked of the environment rather than of the slot, and that distinction is
  # the point: retiring a slot deletes its row for that build and `prune_builds`
  # drops the older ones, so a per-slot version of this clause would let a slot
  # that left the game four builds ago run out of rows and quietly reappear.
  test ".in_build excludes a slot with no row once the environment has any" do
    retired = create(:hardpoint, :without_build, source: :game_files)
    create(:hardpoint, source: :game_files)

    assert_not_includes Hardpoint.in_build.pluck(:id), retired.id
  end

  test ".in_build resolves against the source asked for" do
    hardpoint = create(:hardpoint, :without_build, source: :game_files)
    create(:hardpoint_build, hardpoint:, environment: "ptu", version: "9.9.9-ptu.1")
    # So the live half has rows of its own and the transition clause stays shut.
    create(:hardpoint, source: :game_files)

    assert_not_includes Hardpoint.in_build.pluck(:id), hardpoint.id

    ScData::Source.with(ScData::Source.new(environment: "ptu", version: "9.9.9-ptu.1")) do
      assert_includes Hardpoint.in_build.pluck(:id), hardpoint.id
    end
  end

  test "goes away with the slot it describes" do
    hardpoint = create(:hardpoint, :without_build, source: :game_files)
    build_row = create(:hardpoint_build, hardpoint:)

    hardpoint.destroy!

    assert_not HardpointBuild.exists?(build_row.id)
  end
end
