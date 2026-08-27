# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: model_builds
#
#  id                      :uuid             not null, primary key
#  cargo_holds             :string
#  environment             :string           not null
#  external_fuel_tanks     :string
#  ground                  :boolean          default(FALSE)
#  ground_acceleration     :decimal(15, 2)
#  ground_decceleration    :decimal(15, 2)
#  ground_max_speed        :decimal(15, 2)
#  ground_reverse_speed    :decimal(15, 2)
#  hull_doors              :jsonb
#  hull_health             :decimal(15, 2)
#  hull_parts              :jsonb
#  hydrogen_fuel_tanks     :string
#  mass                    :decimal(15, 2)
#  max_speed               :decimal(15, 2)
#  personal_inventory      :decimal(15, 2)
#  pitch                   :decimal(15, 2)
#  pitch_boosted           :decimal(15, 2)
#  quantum_fuel_tanks      :string
#  refuel_boom             :string
#  reverse_speed_boosted   :decimal(15, 2)
#  roll                    :decimal(15, 2)
#  roll_boosted            :decimal(15, 2)
#  scm_speed               :decimal(15, 2)
#  scm_speed_boosted       :decimal(15, 2)
#  signature_cross_section :jsonb
#  version                 :string           not null
#  weapon_pool_size        :integer
#  yaw                     :decimal(15, 2)
#  yaw_boosted             :decimal(15, 2)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  model_id                :uuid             not null
#
# Indexes
#
#  index_model_builds_on_environment_and_version  (environment,version)
#  index_model_builds_on_model_and_build          (model_id,environment,version) UNIQUE
#  index_model_builds_on_model_id                 (model_id)
#
# Foreign Keys
#
#  fk_rails_...  (model_id => models.id) ON DELETE => cascade
#
class ModelBuildTest < ActiveSupport::TestCase
  setup do
    @environment = ScData::Source.environment
  end

  test "a model carries one row per build, not two" do
    model = create(:model)
    create(:model_build, model:, environment: @environment, version: "1.0.0")

    duplicate = build(:model_build, model:, environment: @environment, version: "1.0.0")

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :model_id
  end

  test "a later build of the same environment sits beside the earlier one" do
    model = create(:model)
    create(:model_build, model:, environment: @environment, version: "1.0.0")

    assert_difference("ModelBuild.count", 1) do
      create(:model_build, model:, environment: @environment, version: "1.0.1")
    end
  end

  # The same version in two environments is two builds: live and ptu ship the
  # same version string while carrying different data.
  test "the same model can be described by more than one environment" do
    model = create(:model)
    create(:model_build, model:, environment: "live", version: "1.0.0")

    assert_difference("ModelBuild.count", 1) do
      create(:model_build, model:, environment: "ptu", version: "1.0.0")
    end
  end

  test "requires the model it describes, and a build to be" do
    orphan = build(:model_build, model: nil, environment: nil, version: nil)

    assert_not orphan.valid?
    assert_includes orphan.errors.attribute_names, :model
    assert_includes orphan.errors.attribute_names, :environment
    assert_includes orphan.errors.attribute_names, :version
  end

  test ".for_source keeps only the current environment" do
    model = create(:model)
    live = create(:model_build, model:, environment: @environment, version: "1.0.0")
    other = create(:model_build, model:, environment: "ptu", version: "1.0.0")

    assert_includes ModelBuild.for_source, live
    assert_not_includes ModelBuild.for_source, other
  end

  test ".current also narrows to the version the environment is on" do
    model = create(:model)
    current = create(:model_build, model:, environment: @environment, version: ScData::Source.version)
    older = create(:model_build, model:, environment: @environment, version: "0.0.1-live.1")

    assert_includes ModelBuild.current, current
    assert_not_includes ModelBuild.current, older
  end

  # All five of them, together. Declaring one and assuming the rest is what broke
  # the components expand: the reader falls through to the column only on nil, and
  # a raw YAML string is not nil, so a caller calling `dig` on it got the string.
  test "every serialized fact comes back as the structure it went in as" do
    cargo_holds = [{"dimensions" => {"x" => 1.25, "y" => 7.5, "z" => 1.25}, "capacity" => 6}]
    quantum = [{"name" => "quantum_fuel_tank", "capacity" => 3_000.0}]
    hydrogen = [{"name" => "hydrogen_fuel_tank", "capacity" => 660_000.0}]
    external = [{"name" => "external_fuel_tank", "capacity" => 12_000.0}]
    refuel_boom = {"name" => "refuel_boom", "rate" => 5.0}

    build = create(
      :model_build,
      cargo_holds:, quantum_fuel_tanks: quantum, hydrogen_fuel_tanks: hydrogen,
      external_fuel_tanks: external, refuel_boom:
    )

    build.reload

    assert_equal cargo_holds, build.cargo_holds
    assert_equal quantum, build.quantum_fuel_tanks
    assert_equal hydrogen, build.hydrogen_fuel_tanks
    assert_equal external, build.external_fuel_tanks
    assert_equal refuel_boom, build.refuel_boom
  end

  # The jsonb facts are native rather than serialized, so this pins that they were
  # not given a coder they do not need.
  test "the jsonb facts keep their structure without a coder" do
    hull_parts = [{"name" => "hull_front", "health" => 12_000.0}]
    hull_doors = [{"name" => "door_cargo", "health" => 900.0}]
    cross_section = {"x" => 1.0, "y" => 0.5, "z" => 0.75}

    build = create(:model_build, hull_parts:, hull_doors:, signature_cross_section: cross_section)

    build.reload

    assert_equal hull_parts, build.hull_parts
    assert_equal hull_doors, build.hull_doors
    assert_equal cross_section, build.signature_cross_section
  end

  # Dimensions are deliberately absent: a ship ships up to three unlabelled size
  # sets and no source says which a number belongs to, so a build row would
  # enshrine one of them as the dimension.
  test "a build carries no dimensions and no in-game flag" do
    %w[length beam height sc_length sc_beam sc_height in_game production_status].each do |column|
      refute_includes ModelBuild.column_names, column
    end
  end

  test "a build carries nothing the ship matrix supplies" do
    assert_empty ModelBuild.column_names.grep(/\Arsi_/)
  end

  test ".retained_versions keeps the newest builds of an environment" do
    model = create(:model)
    %w[0.0.1 0.0.2 0.0.3 0.0.4].each_with_index do |version, index|
      create(
        :model_build,
        model:, environment: @environment, version:,
        created_at: index.days.ago.end_of_day
      )
    end

    assert_equal %w[0.0.2 0.0.1], ModelBuild.retained_versions(@environment, keep: 2)
  end

  test "builds go when the model does" do
    model = create(:model)
    create(:model_build, model:)

    assert_difference("ModelBuild.count", -1) do
      model.destroy
    end
  end
end
