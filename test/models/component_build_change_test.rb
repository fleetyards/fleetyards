# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: component_build_changes
#
#  id           :uuid             not null, primary key
#  environment  :string           not null
#  field        :string           not null
#  from_version :string           not null
#  new_value    :text
#  old_value    :text
#  recorded_at  :datetime         not null
#  to_version   :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  component_id :uuid             not null
#
# Indexes
#
#  index_component_build_changes_on_build              (environment,to_version)
#  index_component_build_changes_on_component_and_field  (component_id,environment,to_version,field) UNIQUE
#  index_component_build_changes_on_recorded_at        (recorded_at)
#
# Foreign Keys
#
#  fk_rails_...  (component_id => components.id) ON DELETE => cascade
#
class ComponentBuildChangeTest < ActiveSupport::TestCase
  setup do
    @component = create(:component, :without_build)
    @environment = ScData::Source.environment
  end

  test ".record! writes a row per fact the patch changed" do
    previous_build(size: "2", grade: "A")
    build = current_build(size: "3", grade: "A")

    assert_equal 1, ComponentBuildChange.record!(build)

    change = ComponentBuildChange.sole
    assert_equal "size", change.field
    assert_equal "2", change.old_value
    assert_equal "3", change.new_value
    assert_equal "4.9.0", change.from_version
    assert_equal ScData::Source.version, change.to_version
  end

  test ".record! records nothing when the patch changed nothing" do
    previous_build(size: "2")
    build = current_build(size: "2")

    assert_equal 0, ComponentBuildChange.record!(build)
    assert_empty ComponentBuildChange.all
  end

  # The first build a component ever gets has nothing to be measured against.
  test ".record! records nothing without a preceding build" do
    build = current_build(size: "2")

    assert_equal 0, ComponentBuildChange.record!(build)
    assert_empty ComponentBuildChange.all
  end

  # The same export parsed twice can produce different values without a version
  # bump, so the second parse replaces the first rather than piling up beside it.
  test ".record! replaces what it already recorded for the build" do
    previous_build(size: "2")
    build = current_build(size: "3")
    ComponentBuildChange.record!(build)

    build.update!(size: "4")
    ComponentBuildChange.record!(build)

    assert_equal "4", ComponentBuildChange.sole.new_value
  end

  test ".record! drops a row for a fact that stopped differing" do
    previous_build(size: "2")
    build = current_build(size: "3")
    ComponentBuildChange.record!(build)

    build.update!(size: "2")
    ComponentBuildChange.record!(build)

    assert_empty ComponentBuildChange.all
  end

  test ".record! ignores a build of another environment" do
    create(
      :component_build,
      component: @component, environment: "ptu", version: "4.9.0",
      size: "9", created_at: 2.months.ago
    )
    build = current_build(size: "2")

    assert_equal 0, ComponentBuildChange.record!(build)
  end

  test ".record! measures against the most recent earlier build" do
    create(
      :component_build,
      component: @component, environment: @environment, version: "4.8.0",
      size: "1", created_at: 6.months.ago
    )
    previous_build(size: "2")
    build = current_build(size: "3")

    ComponentBuildChange.record!(build)

    assert_equal "2", ComponentBuildChange.sole.old_value
  end

  # Loading an older tree by hand is how a re-parse of a past version is checked,
  # and it leaves a build whose newest sibling is newer than itself. Measured
  # against that one, the patch is recorded backwards.
  test ".record! ignores a build that landed after this one" do
    create(
      :component_build,
      component: @component, environment: @environment, version: "4.11.0",
      name: "Sunrise Shield", size: "9", created_at: 1.hour.ago
    )
    previous_build(size: "2")
    build = current_build(size: "3")

    assert_equal 1, ComponentBuildChange.record!(build)

    change = ComponentBuildChange.sole
    assert_equal "4.9.0", change.from_version
    assert_equal "2", change.old_value
  end

  test ".record! records a fact the previous build did not carry" do
    previous_build(size: "2", grade: nil)
    build = current_build(size: "2", grade: "A")

    ComponentBuildChange.record!(build)

    change = ComponentBuildChange.sole
    assert_equal "grade", change.field
    assert_nil change.old_value
    assert_equal "A", change.new_value
  end

  # The figures a reader came to the page for live inside `type_data`, not in a
  # column -- a weapon whose damage moved has changed in the only way that
  # matters, and every build column stays identical while it does.
  test ".record! diffs the scalar metrics inside type_data" do
    previous_build(type_data: {"damage_per_shot" => 120, "fire_rate" => 600})
    build = current_build(type_data: {"damage_per_shot" => 140, "fire_rate" => 600})

    assert_equal 1, ComponentBuildChange.record!(build)

    change = ComponentBuildChange.sole
    assert_equal "type_data.damage_per_shot", change.field
    assert_equal "120", change.old_value
    assert_equal "140", change.new_value
    assert_predicate change, :metric?
    assert_equal "damage_per_shot", change.field_name
  end

  test ".record! records a metric the patch added and one it took away" do
    previous_build(type_data: {"regen" => 50})
    build = current_build(type_data: {"cooling_rate" => 80})

    assert_equal 2, ComponentBuildChange.record!(build)

    assert_equal(
      [["type_data.cooling_rate", nil, "80"], ["type_data.regen", "50", nil]],
      ComponentBuildChange.order(:field).pluck(:field, :old_value, :new_value)
    )
  end

  # A nested shape has no one-line "from -> to" to render, and a re-parse can
  # order it differently with nothing having changed.
  test ".record! leaves the nested parts of type_data alone" do
    previous_build(type_data: {"calibration" => {"rate" => 1}, "regen" => 50})
    build = current_build(type_data: {"calibration" => {"rate" => 9}, "regen" => 50})

    assert_equal 0, ComponentBuildChange.record!(build)
  end

  # Two loads of the same export can serialise these differently with nothing
  # having changed, which would otherwise report a change every single patch.
  test ".record! leaves the structured columns alone" do
    previous_build(size: "2", ammunition: {"a" => 1}, inventory_consumption: {"micro_scu" => 2})
    build = current_build(size: "2", ammunition: {"b" => 9}, inventory_consumption: {"micro_scu" => 7})

    assert_equal 0, ComponentBuildChange.record!(build)
  end

  # Prose and a uuid both read as noise beside "size 2 -> 3".
  test ".record! leaves description and the manufacturer alone" do
    manufacturer = create(:manufacturer)
    previous_build(size: "2", description: "A shield.", manufacturer: nil)
    build = current_build(size: "2", description: "A better shield.", manufacturer:)

    assert_equal 0, ComponentBuildChange.record!(build)
  end

  # The name is pinned rather than left to the factory's sequence: two builds of
  # the same component carrying different names would report a `name` change in
  # every one of these, on top of the fact each is actually about.
  private def previous_build(attributes)
    create(
      :component_build,
      component: @component, environment: @environment, version: "4.9.0",
      name: "Sunrise Shield", created_at: 2.months.ago, **attributes
    )
  end

  private def current_build(attributes)
    create(
      :component_build,
      component: @component, environment: @environment, version: ScData::Source.version,
      name: "Sunrise Shield", created_at: 1.day.ago, **attributes
    )
  end
end
