# frozen_string_literal: true

require "test_helper"

module ScData
  class PatchSummaryTest < ActiveSupport::TestCase
    PREVIOUS = ::ScData::Source.new(environment: "live", version: "1.0.0-live.1")
    CURRENT = ::ScData::Source.new(environment: "live", version: "1.0.1-live.2")
    HOTFIX = ::ScData::Source.new(environment: "live", version: "1.0.1-live.3")

    private def model_build(source, model:, **facts)
      create(:model_build, model:, environment: source.environment, version: source.version, **facts)
    end

    private def equipment_build(source, equipment:, **facts)
      create(:equipment_build, equipment:, environment: source.environment, version: source.version, **facts)
    end

    # A hotfix adds to its patch: the patch is what a reader asks about, and two
    # builds of one patch differ by a handful of items.
    test ".for compares the newest build against the last build of the patch before it" do
      model = create(:model)
      model_build(PREVIOUS, model:)
      model_build(CURRENT, model:)
      model_build(HOTFIX, model:)

      summary = ::ScData::PatchSummary.for("live")

      assert_equal PREVIOUS, summary.from
      assert_equal HOTFIX, summary.to
    end

    test ".for falls back to the build before when only one patch is recorded" do
      model = create(:model)
      model_build(CURRENT, model:)
      model_build(HOTFIX, model:)

      assert_equal CURRENT, ::ScData::PatchSummary.for("live").from
    end

    test ".for has nothing to summarise with a single build" do
      model_build(CURRENT, model: create(:model))

      assert_nil ::ScData::PatchSummary.for("live")
    end

    test "#call lists a ship the newer build describes and the older one does not" do
      model_build(PREVIOUS, model: create(:model))
      arrived = create(:model)
      model_build(CURRENT, model: arrived)

      result = ::ScData::PatchSummary.new(from: PREVIOUS, to: CURRENT).call

      assert_equal [arrived.id], result[:new_ship_ids]
      assert_equal 1, result[:counts][:new_ships]
    end

    test "#call leaves out ships nobody can open" do
      model_build(PREVIOUS, model: create(:model))
      model_build(CURRENT, model: create(:model, :hidden))

      result = ::ScData::PatchSummary.new(from: PREVIOUS, to: CURRENT).call

      assert_empty result[:new_ship_ids]
      assert_equal 0, result[:counts][:new_ships]
    end

    test "#call reads both values of every fact that moved" do
      model = create(:model)
      model_build(PREVIOUS, model:, mass: 386_857, hull_health: 180_844)
      model_build(CURRENT, model:, mass: 367_247, hull_health: 103_004)

      change = ::ScData::PatchSummary.new(from: PREVIOUS, to: CURRENT).call[:ship_changes].sole

      assert_equal model.id, change[:id]
      assert_includes change[:fields], {field: "hull_health", from: 180_844.0, to: 103_004.0}
      assert_includes change[:fields], {field: "mass", from: 386_857.0, to: 367_247.0}
    end

    # Fuel consumption is the sum of what a ship's thrusters draw, which we
    # compute. A change to that formula moves every ship and says nothing about
    # the patch.
    test "#call leaves out the facts we derive ourselves" do
      model = create(:model)
      model_build(PREVIOUS, model:, fuel_consumption: 2.26)
      model_build(CURRENT, model:, fuel_consumption: 7036.73)

      result = ::ScData::PatchSummary.new(from: PREVIOUS, to: CURRENT).call

      assert_empty result[:ship_changes]
      assert_equal 0, result[:counts][:changed_ships]
    end

    test "#call leads with what moved the most" do
      nudged = create(:model)
      model_build(PREVIOUS, model: nudged, mass: 1_000)
      model_build(CURRENT, model: nudged, mass: 1_010)
      halved = create(:model)
      model_build(PREVIOUS, model: halved, mass: 1_000)
      model_build(CURRENT, model: halved, mass: 500)

      changes = ::ScData::PatchSummary.new(from: PREVIOUS, to: CURRENT).call[:ship_changes]

      assert_equal [halved.id, nudged.id], changes.pluck(:id)
    end

    test "#call lists item changes with their values" do
      equipment = create(:equipment, :without_build)
      equipment_build(PREVIOUS, equipment:, name: "Streamline", rate_of_fire: 550)
      equipment_build(CURRENT, equipment:, name: "Streamline", rate_of_fire: 400)

      change = ::ScData::PatchSummary.new(from: PREVIOUS, to: CURRENT).call[:item_changes].sole

      assert_equal "equipment", change[:kind]
      assert_equal [{field: "rate_of_fire", from: 550.0, to: 400.0}], change[:fields]
    end
  end
end
