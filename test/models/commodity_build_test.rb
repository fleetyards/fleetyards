# frozen_string_literal: true

require "test_helper"

class CommodityBuildTest < ActiveSupport::TestCase
  setup do
    @environment = ScData::Source.environment
  end

  test "a commodity carries one row per build, not two" do
    commodity = create(:commodity, :without_build)
    create(:commodity_build, commodity:, environment: @environment, version: "1.0.0")

    duplicate = build(:commodity_build, commodity:, environment: @environment, version: "1.0.0")

    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :commodity_id
  end

  test "a later build of the same environment sits beside the earlier one" do
    commodity = create(:commodity, :without_build)
    create(:commodity_build, commodity:, environment: @environment, version: "1.0.0")

    assert_difference("CommodityBuild.count", 1) do
      create(:commodity_build, commodity:, environment: @environment, version: "1.0.1")
    end
  end

  # The same version in two environments is two builds: live and ptu ship the
  # same version string while carrying different data.
  test "the same commodity can be described by more than one environment" do
    commodity = create(:commodity, :without_build)
    create(:commodity_build, commodity:, environment: "live", version: "1.0.0")

    assert_difference("CommodityBuild.count", 1) do
      create(:commodity_build, commodity:, environment: "ptu", version: "1.0.0")
    end
  end

  test "requires the commodity it describes, and a build to be" do
    orphan = build(:commodity_build, commodity: nil, environment: nil, version: nil)

    assert_not orphan.valid?
    assert_includes orphan.errors.attribute_names, :commodity
    assert_includes orphan.errors.attribute_names, :environment
    assert_includes orphan.errors.attribute_names, :version
  end

  test ".for_source keeps only the current environment" do
    commodity = create(:commodity, :without_build)
    live = create(:commodity_build, commodity:, environment: @environment, version: "1.0.0")
    other = create(:commodity_build, commodity:, environment: "ptu", version: "1.0.0")

    assert_includes CommodityBuild.for_source, live
    assert_not_includes CommodityBuild.for_source, other
  end

  test ".current also narrows to the version the environment is on" do
    commodity = create(:commodity, :without_build)
    current = create(:commodity_build, commodity:, environment: @environment, version: ScData::Source.version)
    older = create(:commodity_build, commodity:, environment: @environment, version: "0.0.1-live.1")

    assert_includes CommodityBuild.current, current
    assert_not_includes CommodityBuild.current, older
  end

  test ".retained_versions keeps the newest builds of an environment" do
    commodity = create(:commodity, :without_build)
    %w[0.0.1 0.0.2 0.0.3 0.0.4].each_with_index do |version, index|
      create(
        :commodity_build,
        commodity:, environment: @environment, version:,
        created_at: index.days.ago.end_of_day
      )
    end

    assert_equal %w[0.0.2 0.0.1], CommodityBuild.retained_versions(@environment, keep: 2)
  end

  test "builds go when the commodity does" do
    commodity = create(:commodity, :without_build)
    create(:commodity_build, commodity:)

    assert_difference("CommodityBuild.count", -1) do
      commodity.destroy
    end
  end
end
