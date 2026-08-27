# frozen_string_literal: true

require "test_helper"

class ComponentBuildTest < ActiveSupport::TestCase
  setup do
    @environment = ScData::Source.environment
    @version = ScData::Source.version
  end

  test "a component carries one row per build, not two" do
    component = create(:component)
    create(:component_build, component:, environment: @environment, version: @version)

    duplicate = build(
      :component_build, component:, environment: @environment, version: @version
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :component_id
  end

  test "a later build of the same environment sits beside the earlier one" do
    component = create(:component)
    create(:component_build, component:, environment: @environment, version: "0.0.1-live.1")
    create(:component_build, component:, environment: @environment, version: "0.0.2-live.2")

    assert_equal 2, component.builds.count
  end

  test "the same component can be described by more than one environment" do
    component = create(:component)
    create(:component_build, component:, environment: "live", version: @version)
    create(:component_build, component:, environment: "ptu", version: @version)

    assert_equal 2, component.builds.count
  end

  test "requires the build it describes" do
    build_row = build(:component_build, environment: nil, version: nil)

    assert_not build_row.valid?
    assert_includes build_row.errors.attribute_names, :environment
    assert_includes build_row.errors.attribute_names, :version
  end

  test ".for_source keeps only the current environment" do
    component = create(:component)
    mine = create(:component_build, component:, environment: @environment, version: @version)
    create(:component_build, component:, environment: "somewhere-else", version: @version)

    assert_equal [mine.id], ComponentBuild.for_source.pluck(:id)
  end

  test ".current also narrows to the version the environment is on" do
    component = create(:component)
    current = create(:component_build, component:, environment: @environment, version: @version)
    create(:component_build, component:, environment: @environment, version: "0.0.1-live.1")

    assert_equal [current.id], ComponentBuild.current.pluck(:id)
  end

  # A build row holding 0 has to read back as its name, or moving the readers over
  # turns every enum-backed fact into a raw integer.
  test "the enums keep their names" do
    build_row = create(:component_build, item_class: :military, tracking_signal: :infrared)

    assert_equal "military", build_row.reload.item_class
    assert_equal "infrared", build_row.tracking_signal
  end

  # Component serializes this column as YAML, so the build has to as well --
  # otherwise the structure comes back as the string it was encoded into.
  test "durability comes back as the structure it went in as" do
    durability = {"health" => 1200, "parts" => ["front", "rear"]}
    build_row = create(:component_build, durability:)

    assert_equal durability, build_row.reload.durability
  end

  test ".retained_versions keeps the newest builds of an environment" do
    component = create(:component)
    %w[0.0.1 0.0.2 0.0.3 0.0.4].each_with_index do |version, index|
      create(
        :component_build,
        component:, environment: @environment, version:,
        created_at: index.days.ago.end_of_day
      )
    end

    retained = ComponentBuild.retained_versions(@environment, keep: 2)

    assert_equal %w[0.0.2 0.0.1], retained
  end

  test "builds go when the component does" do
    component = create(:component)
    create(:component_build, component:)

    assert_difference("ComponentBuild.count", -1) do
      component.destroy
    end
  end
end
