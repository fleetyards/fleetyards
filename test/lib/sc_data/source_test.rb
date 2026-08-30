# frozen_string_literal: true

require "test_helper"

class ScData::SourceTest < ActiveSupport::TestCase
  def stub_config(sources:, default: nil)
    Rails.configuration.stubs(:sc_data).returns({sources:, default:}.compact)
  end

  test "reads every source the config declares, in order" do
    stub_config(sources: {live: "1.0.0", ptu: "1.1.0"})

    assert_equal ["1.0.0 (live)", "1.1.0 (ptu)"], ScData::Source.configured.map(&:to_s)
  end

  test "the default is the one the config names" do
    stub_config(sources: {live: "1.0.0", ptu: "1.1.0"}, default: "ptu")

    assert_equal "ptu", ScData::Source.default.environment
  end

  # A config that names no default still has to answer, or every caller breaks.
  test "falls back to the first source when the config names no default" do
    stub_config(sources: {live: "1.0.0", ptu: "1.1.0"})

    assert_equal "live", ScData::Source.default.environment
  end

  test "a default naming a source that is not there falls back too" do
    stub_config(sources: {live: "1.0.0"}, default: "nowhere")

    assert_equal "live", ScData::Source.default.environment
  end

  # Nothing sets a source by default, so every existing caller keeps getting the
  # configured one.
  test "the current source is the default until something says otherwise" do
    stub_config(sources: {live: "1.0.0", ptu: "1.1.0"})

    assert_equal ScData::Source.default, ScData::Source.current
  end

  test ".with puts a source in force and takes it back out" do
    stub_config(sources: {live: "1.0.0", ptu: "1.1.0"})
    ptu = ScData::Source.find("ptu")

    ScData::Source.with(ptu) do
      assert_equal ptu, ScData::Source.current
      assert_equal "1.1.0", ScData::Source.version
    end

    assert_equal "live", ScData::Source.current.environment
  end

  # A job inside a request must not strand the outer value.
  test ".with nests" do
    stub_config(sources: {live: "1.0.0", ptu: "1.1.0"})
    live = ScData::Source.find("live")
    ptu = ScData::Source.find("ptu")

    ScData::Source.with(ptu) do
      ScData::Source.with(live) do
        assert_equal live, ScData::Source.current
      end

      assert_equal ptu, ScData::Source.current, "the outer source came back"
    end
  end

  test ".with puts the source back even when the block raises" do
    stub_config(sources: {live: "1.0.0", ptu: "1.1.0"})

    assert_raises(RuntimeError) do
      ScData::Source.with(ScData::Source.find("ptu")) { raise "boom" }
    end

    assert_equal "live", ScData::Source.current.environment
  end

  # An environment nothing has loaded would answer every question with nothing,
  # so it is not offered rather than served empty.
  test "a source counts as available only once a catalogue carries a build for it" do
    stub_config(sources: {live: "1.0.0", ptu: "1.1.0"})

    assert_empty ScData::Source.available

    create(:equipment, :without_build).builds.create!(environment: "ptu", version: "1.1.0")

    assert_equal ["ptu"], ScData::Source.available.map(&:environment)
  end

  test "any of the four catalogues makes a source available" do
    stub_config(sources: {live: "1.0.0"})
    live = ScData::Source.find("live")

    assert_not_predicate live, :loaded?

    create(:model_build, model: create(:model), environment: "live", version: "1.0.0")

    assert_predicate live, :loaded?
  end

  test "a build of another version does not make the source available" do
    stub_config(sources: {live: "1.0.0"})
    create(:model_build, model: create(:model), environment: "live", version: "0.9.0")

    assert_empty ScData::Source.available
  end

  # A finished ptu cycle leaves its tree in place while live moves past it, so
  # the config still names a ptu build long after it stopped being the newer one.
  test "a source behind the default is not offered" do
    stub_config(sources: {live: "4.10.0-live.12519617", ptu: "4.10.0-ptu.12490000"}, default: "live")
    create(:model_build, model: create(:model), environment: "live", version: "4.10.0-live.12519617")
    create(:model_build, model: create(:model), environment: "ptu", version: "4.10.0-ptu.12490000")

    assert_equal ["live"], ScData::Source.available.map(&:environment)
  end

  test "a source ahead of the default is offered" do
    stub_config(sources: {live: "4.9.0-live.12344265", ptu: "4.10.0-ptu.12600000"}, default: "live")
    create(:model_build, model: create(:model), environment: "live", version: "4.9.0-live.12344265")
    create(:model_build, model: create(:model), environment: "ptu", version: "4.10.0-ptu.12600000")

    assert_equal ["live", "ptu"], ScData::Source.available.map(&:environment)
  end

  # Same version on both sides is the moment live catches up: only the build id
  # separates them, and it has to be what decides.
  test "the build id decides when the versions match" do
    stub_config(sources: {live: "4.10.0-live.12519617", ptu: "4.10.0-ptu.12600000"}, default: "live")
    create(:model_build, model: create(:model), environment: "live", version: "4.10.0-live.12519617")
    create(:model_build, model: create(:model), environment: "ptu", version: "4.10.0-ptu.12600000")

    assert_equal ["live", "ptu"], ScData::Source.available.map(&:environment)
  end

  # The default is what everything else is measured against, so it is offered on
  # its own terms -- otherwise a config whose default is the older build would
  # offer nothing at all.
  test "the default is offered even when another source is ahead of it" do
    stub_config(sources: {live: "4.9.0-live.12344265", ptu: "4.10.0-ptu.12600000"}, default: "live")
    create(:model_build, model: create(:model), environment: "live", version: "4.9.0-live.12344265")

    assert_equal ["live"], ScData::Source.available.map(&:environment)
  end

  test "knows whether it is the default" do
    stub_config(sources: {live: "1.0.0", ptu: "1.1.0"}, default: "live")

    assert_predicate ScData::Source.find("live"), :default?
    assert_not_predicate ScData::Source.find("ptu"), :default?
  end
end
