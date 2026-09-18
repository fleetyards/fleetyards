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

    # What makes the build count as served. Rows alone only say a load started.
    create(:import, :scdata_all, aasm_state: :finished, version: @loaded.version)
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

  # A load commits its catalogues one at a time and does not roll them back, so
  # the first row of a new build would otherwise hand the whole site over to a
  # half-written one -- turning a complete previous patch into a visibly
  # shrinking current one, which is worse than the empty window this all started
  # from.
  test "a build whose load is still running is not served yet" do
    create(:component_build, component: create(:component, :without_build),
      environment: "live", version: @bumped.version)

    assert_equal @loaded.version, Component.served_source(@bumped).version
  end

  test "it serves the build once that load finishes" do
    create(:component_build, component: create(:component, :without_build),
      environment: "live", version: @bumped.version)
    create(:import, :scdata_all, aasm_state: :finished, version: @bumped.version)

    assert_equal @bumped.version, Component.served_source(@bumped).version
  end

  # Not the import window but a truncated ledger, where insisting on a marker
  # that no longer exists would empty every catalogue on the site.
  test "rows with no ledger entry at all are still served" do
    Import.delete_all

    assert_equal @loaded.version, Component.served_source(@bumped).version
  end

  # Component resolved its fact join and the other three did not, so they
  # selected the previous patch's rows and then inner-joined facts at a build
  # with none. The scope lives in one place now, which is what stops that.
  test "every catalogue joins its facts at the build it selected" do
    {Commodity => :commodity, Equipment => :equipment, Blueprint => :blueprint}.each do |model, name|
      record = create(name, :without_build)
      create(:"#{name}_build", name => record, :environment => "live", :version => @loaded.version)

      assert_equal [record.id], model.with_facts(true, @bumped).pluck(:id),
        "#{model} emptied its catalogue during the fallback window"
    end
  end
end
