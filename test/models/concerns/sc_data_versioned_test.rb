# frozen_string_literal: true

require "test_helper"

# The config names a build as soon as it is parsed and pushed; the rows for it
# arrive when the load runs, which is up to a day later. Read strictly, every
# catalogue that joins its build inner-wise answers nothing for that window.
class ScDataVersionedTest < ActiveSupport::TestCase
  setup do
    @loaded = ScData::Source.new(version: "1.0.0-live.1", environment: "live")
    @bumped = ScData::Source.new(version: "2.0.0-live.2", environment: "live")

    @component = create(:component, :without_build)
    create(:component_build, component: @component, environment: "live", version: @loaded.version)
  end

  test "a configured build that has rows serves itself" do
    assert_equal @loaded.version, Component.served_source(@loaded).version
  end

  test "a configured build with no rows yet serves the last one loaded" do
    assert_equal @loaded.version, Component.served_source(@bumped).version
  end

  test "the catalogue answers from the previous patch rather than emptying" do
    assert_equal [@component.id], Component.current_version(true, @bumped).pluck(:id)
  end

  # Otherwise a bump would quietly serve another environment's data.
  test "the fallback stays inside its own environment" do
    ptu = ScData::Source.new(version: "2.0.0-ptu.2", environment: "ptu")

    assert_equal ptu.version, Component.served_source(ptu).version
    assert_empty Component.current_version(true, ptu).pluck(:id)
  end

  # `ScData::CheckJob` asks `current` whether the new build has landed. A
  # fallback there would answer yes for ever and the load would never run.
  test "the exact-build scope keeps meaning exactly that build" do
    assert_not ComponentBuild.current(@bumped).exists?
    assert ComponentBuild.current(@loaded).exists?
  end

  test "an environment with no builds at all serves what it was given" do
    nowhere = ScData::Source.new(version: "3.0.0-live.3", environment: "nowhere")

    assert_equal nowhere.version, Component.served_source(nowhere).version
  end
end
