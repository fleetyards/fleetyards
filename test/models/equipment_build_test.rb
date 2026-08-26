# frozen_string_literal: true

require "test_helper"

# The first catalogue to say what a build claims about an item separately from
# what the item is. Equipment keeps its identity and anything a person set; the
# loader's values live here, one row per environment.
# == Schema Information
#
# Table name: equipment_builds
#
#  id                     :uuid             not null, primary key
#  backpack_compatibility :integer
#  core_compatibility     :integer
#  damage_reduction       :decimal(15, 2)
#  description            :text
#  environment            :string           not null
#  equipment_type         :string
#  g_force_tolerance      :decimal(15, 2)
#  grade                  :string
#  hidden                 :boolean          default(FALSE)
#  item_type              :string
#  name                   :string
#  radiation_protection   :decimal(15, 2)
#  radiation_scrub_rate   :decimal(15, 2)
#  range                  :decimal(15, 2)
#  rate_of_fire           :decimal(15, 2)
#  size                   :string
#  slot                   :integer
#  storage                :decimal(15, 2)
#  sub_type               :string
#  temperature_rating     :string
#  version                :string           not null
#  volume                 :decimal(15, 6)
#  volume_dimensions      :jsonb
#  weapon_class           :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  equipment_id           :uuid             not null
#  manufacturer_id        :uuid
#
# Indexes
#
#  index_equipment_builds_on_environment_and_equipment_type  (environment,equipment_type)
#  index_equipment_builds_on_environment_and_item_type       (environment,item_type)
#  index_equipment_builds_on_environment_and_version         (environment,version)
#  index_equipment_builds_on_equipment_and_build             (equipment_id,environment,version) UNIQUE
#  index_equipment_builds_on_equipment_id                    (equipment_id)
#  index_equipment_builds_on_manufacturer_id                 (manufacturer_id)
#
# Foreign Keys
#
#  fk_rails_...  (equipment_id => equipment.id) ON DELETE => cascade
#
class EquipmentBuildTest < ActiveSupport::TestCase
  test "an item carries one row per build, not two" do
    equipment = create(:equipment)
    create(:equipment_build, equipment:, environment: "live", version: "4.9.0-live.1")

    duplicate = build(:equipment_build, equipment:, environment: "live", version: "4.9.0-live.1")

    refute_predicate duplicate, :valid?
    assert_includes duplicate.errors.attribute_names, :equipment_id
  end

  # The point of keeping history: a later build lands beside its predecessor
  # rather than overwriting it.
  test "a later build of the same environment sits beside the earlier one" do
    equipment = create(:equipment)
    create(:equipment_build, equipment:, environment: "live", version: "4.9.0-live.1")

    assert_predicate build(:equipment_build, equipment:, environment: "live", version: "4.10.0-live.2"), :valid?
  end

  test "the same item can be described by more than one environment" do
    equipment = create(:equipment)
    create(:equipment_build, equipment:, environment: "live")

    assert_predicate build(:equipment_build, equipment:, environment: "ptu"), :valid?
  end

  test "requires the build it describes" do
    refute_predicate build(:equipment_build, version: nil), :valid?
    refute_predicate build(:equipment_build, environment: nil), :valid?
  end

  # `for_source` is what the `build` association narrows by, so an environment
  # only ever sees its own row.
  test ".for_source keeps only the current environment" do
    equipment = create(:equipment)
    live = create(:equipment_build, equipment:, environment: ScData::Source.environment)
    other = create(:equipment_build, equipment:, environment: "somewhere-else")

    assert_includes EquipmentBuild.for_source, live
    refute_includes EquipmentBuild.for_source, other
  end

  # An environment that has moved on leaves its old row behind until the next
  # load rewrites it, so the version is checked as well as the environment.
  test ".current also narrows to the version the environment is on" do
    equipment = create(:equipment)
    current = create(:equipment_build, equipment:)
    stale = create(:equipment_build, equipment: create(:equipment), version: "0.0.1-live.1")

    assert_includes EquipmentBuild.current, current
    refute_includes EquipmentBuild.current, stale
  end

  test "#build returns the row for the current environment" do
    equipment = create(:equipment)
    create(:equipment_build, equipment:, environment: "somewhere-else")
    current = create(:equipment_build, equipment:, environment: ScData::Source.environment)

    assert_equal current, equipment.reload.build
  end

  # Ordered by when a build first appeared, so re-loading an old build does not
  # promote it past the ones that came after.
  test ".retained_versions keeps the newest builds of an environment" do
    %w[4.8.0-live.1 4.9.0-live.2 4.10.0-live.3 4.11.0-live.4].each_with_index do |version, index|
      create(
        :equipment_build,
        equipment: create(:equipment), environment: "live", version:,
        created_at: index.days.ago.end_of_day
      )
    end

    retained = EquipmentBuild.retained_versions("live", keep: 3)

    assert_equal %w[4.10.0-live.3 4.9.0-live.2 4.8.0-live.1].sort, retained.sort
    refute_includes retained, "4.11.0-live.4", "the oldest by first-seen falls out"
  end

  test ".retained_versions looks at one environment at a time" do
    create(:equipment_build, environment: "live", version: "4.9.0-live.1")
    create(:equipment_build, environment: "ptu", version: "4.10.0-ptu.2")

    assert_equal ["4.9.0-live.1"], EquipmentBuild.retained_versions("live")
  end

  test "builds go when the item does" do
    equipment = create(:equipment)
    create(:equipment_build, equipment:)

    assert_difference("EquipmentBuild.count", -1) { equipment.destroy }
  end
end
