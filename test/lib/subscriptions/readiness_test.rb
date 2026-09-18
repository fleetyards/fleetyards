# frozen_string_literal: true

require "test_helper"

module Subscriptions
  class ReadinessTest < ActiveSupport::TestCase
    setup do
      @fleet = create(:fleet)
    end

    test "counts a fleet holding an actor gate itself" do
      Flipper.enable_actor("fleet_contracts", @fleet)

      assert_equal [@fleet.id], Readiness.call[:gated_fleet_ids]
    end

    # The half that gets forgotten. `Flipper.enabled?(flag, user, fleet)` ORs,
    # so a member carrying the gate personally has been reaching the surface on
    # every fleet they belong to -- and that fleet holds no gate of its own.
    test "counts a fleet whose member holds the gate" do
      member = create(:user)
      create(:fleet_membership, :accepted, fleet: @fleet, user: member)
      Flipper.enable_actor("fleet_tours", member)

      assert_equal [@fleet.id], Readiness.call[:gated_fleet_ids]
    end

    test "does not count a fleet the gate holder only asked to join" do
      member = create(:user)
      create(:fleet_membership, fleet: @fleet, user: member, aasm_state: "requested")
      Flipper.enable_actor("fleet_tours", member)

      assert_empty Readiness.call[:gated_fleet_ids]
    end

    test "counts a fleet once when both it and its member hold gates" do
      member = create(:user)
      create(:fleet_membership, :accepted, fleet: @fleet, user: member)
      Flipper.enable_actor("fleet_contracts", @fleet)
      Flipper.enable_actor("fleet_logistics", member)

      assert_equal [@fleet.id], Readiness.call[:gated_fleet_ids]
    end

    test "reads every flag that gates a premium capability" do
      fleets = Readiness::FLAGS.map do |flag|
        create(:fleet).tap { |fleet| Flipper.enable_actor(flag, fleet) }
      end

      assert_equal fleets.map(&:id).sort, Readiness.call[:gated_fleet_ids].sort
    end

    test "a subscribed fleet is not in the unready list" do
      Flipper.enable_actor("fleet_contracts", @fleet)
      create(:fleet_subscription, fleet: @fleet)

      readiness = Readiness.call

      assert_equal [@fleet.id], readiness[:subscribed_fleet_ids]
      assert_empty readiness[:unready_fleet_ids]
    end

    test "a lapsed subscription leaves the fleet unready" do
      Flipper.enable_actor("fleet_contracts", @fleet)
      create(:fleet_subscription, fleet: @fleet, started_at: 1.year.ago, ended_at: 1.day.ago)

      assert_equal [@fleet.id], Readiness.call[:unready_fleet_ids]
    end

    # A gate outlives the row it names: Flipper holds a string, and nothing
    # removes it when the fleet goes.
    test "ignores a gate naming a fleet that no longer exists" do
      Flipper.enable_actor("fleet_contracts", @fleet)
      @fleet.destroy!

      assert_empty Readiness.call[:gated_fleet_ids]
    end

    # The figures describe the wrong population when a flag is on for
    # everybody, and saying so is the whole point of reporting it.
    test "names a flag that is on for everybody" do
      Flipper.enable("fleet_logistics")

      assert_equal ["fleet_logistics"], Readiness.call[:globally_on]
    end

    test "says nothing is globally on when only actors hold gates" do
      Flipper.enable_actor("fleet_contracts", @fleet)

      assert_empty Readiness.call[:globally_on]
    end

    test "counts nobody when no gate is set at all" do
      readiness = Readiness.call

      assert_empty readiness[:gated_fleet_ids]
      assert_empty readiness[:unready_fleet_ids]
    end
  end
end
