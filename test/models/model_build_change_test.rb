# frozen_string_literal: true

require "test_helper"

class ModelBuildChangeTest < ActiveSupport::TestCase
  setup do
    @model = create(:model)
    @environment = ScData::Source.environment
  end

  test ".record! writes a row per fact the patch changed" do
    previous_build(scm_speed: 210, max_speed: 1200)
    build = current_build(scm_speed: 190, max_speed: 1200)

    assert_equal 1, ModelBuildChange.record!(build)

    change = ModelBuildChange.sole
    assert_equal "scm_speed", change.field
    assert_equal 210, change.old_value
    assert_equal 190, change.new_value
    assert_equal "4.9.0", change.from_version
    assert_equal ScData::Source.version, change.to_version
  end

  test ".record! records nothing when the patch changed nothing" do
    previous_build(scm_speed: 210)
    build = current_build(scm_speed: 210)

    assert_equal 0, ModelBuildChange.record!(build)
    assert_empty ModelBuildChange.all
  end

  # The first build a ship ever gets has nothing to be measured against.
  test ".record! records nothing without a preceding build" do
    build = current_build(scm_speed: 210)

    assert_equal 0, ModelBuildChange.record!(build)
    assert_empty ModelBuildChange.all
  end

  # The same export parsed twice can produce different values without a version
  # bump, so the second parse replaces the first rather than piling up beside it.
  test ".record! replaces what it already recorded for the build" do
    previous_build(scm_speed: 210)
    build = current_build(scm_speed: 190)
    ModelBuildChange.record!(build)

    build.update!(scm_speed: 195)
    ModelBuildChange.record!(build)

    change = ModelBuildChange.sole
    assert_equal 195, change.new_value
  end

  test ".record! drops a row for a fact that stopped differing" do
    previous_build(scm_speed: 210)
    build = current_build(scm_speed: 190)
    ModelBuildChange.record!(build)

    build.update!(scm_speed: 210)
    ModelBuildChange.record!(build)

    assert_empty ModelBuildChange.all
  end

  # Two loads of the same export can serialise a shape differently with nothing
  # having changed, which would otherwise report a change every single patch.
  test ".record! leaves the structured facts alone" do
    previous_build(scm_speed: 210, cargo_holds: {"a" => 1}, hull_parts: {"parts" => 2})
    build = current_build(scm_speed: 210, cargo_holds: {"b" => 9}, hull_parts: {"parts" => 7})

    assert_equal 0, ModelBuildChange.record!(build)
  end

  test ".record! ignores a build of another environment" do
    create(
      :model_build,
      model: @model, environment: "ptu", version: "4.9.0",
      scm_speed: 999, created_at: 2.months.ago
    )
    build = current_build(scm_speed: 210)

    assert_equal 0, ModelBuildChange.record!(build)
  end

  test ".record! measures against the most recent earlier build" do
    create(
      :model_build,
      model: @model, environment: @environment, version: "4.8.0",
      scm_speed: 100, created_at: 6.months.ago
    )
    previous_build(scm_speed: 210)
    build = current_build(scm_speed: 190)

    ModelBuildChange.record!(build)

    assert_equal 210, ModelBuildChange.sole.old_value
  end

  test ".record! records a fact the previous build did not carry" do
    previous_build(scm_speed: 210, max_speed: nil)
    build = current_build(scm_speed: 210, max_speed: 1200)

    ModelBuildChange.record!(build)

    change = ModelBuildChange.sole
    assert_equal "max_speed", change.field
    assert_nil change.old_value
    assert_equal 1200, change.new_value
  end

  private def previous_build(attributes)
    create(
      :model_build,
      model: @model, environment: @environment, version: "4.9.0",
      created_at: 2.months.ago, **attributes
    )
  end

  private def current_build(attributes)
    create(
      :model_build,
      model: @model, environment: @environment, version: ScData::Source.version,
      created_at: 1.day.ago, **attributes
    )
  end
end
