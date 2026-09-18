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

    # The figures describe the wrong population when a flag grants through
    # anything that names no actors, and saying so is the whole point.
    test "names a flag that is on for everybody" do
      Flipper.enable("fleet_logistics")

      assert_equal({"fleet_logistics" => [:boolean]}, Readiness.call[:unenumerable_gates])
    end

    # `:testers` is one the app registers, and how the beta was run before the
    # actor gates.
    test "names a flag granting to a group" do
      Flipper.enable_group("fleet_contracts", :testers)

      assert_equal({"fleet_contracts" => [:groups]}, Readiness.call[:unenumerable_gates])
    end

    test "names a flag granting to a percentage of actors" do
      Flipper.enable_percentage_of_actors("fleet_tours", 25)

      assert_equal({"fleet_tours" => [:percentage_of_actors]}, Readiness.call[:unenumerable_gates])
    end

    test "names a flag granting for a percentage of the time" do
      Flipper.enable_percentage_of_time("fleet_logistics", 10)

      assert_equal({"fleet_logistics" => [:percentage_of_time]}, Readiness.call[:unenumerable_gates])
    end

    # A percentage gate set to zero grants nothing, and is not worth halting a
    # run over.
    test "ignores a percentage gate that grants to nobody" do
      Flipper.enable_percentage_of_actors("fleet_tours", 0)

      assert_empty Readiness.call[:unenumerable_gates]
    end

    test "says nothing is unenumerable when only actors hold gates" do
      Flipper.enable_actor("fleet_contracts", @fleet)

      assert_empty Readiness.call[:unenumerable_gates]
    end

    # Discard adds no default scope, so nothing else keeps a deleted fleet out
    # -- and a grace subscription for one is not a thing to create.
    test "ignores a discarded fleet holding a gate" do
      Flipper.enable_actor("fleet_contracts", @fleet)
      @fleet.update_column(:discarded_at, Time.current)

      assert_empty Readiness.call[:gated_fleet_ids]
    end

    test "ignores a discarded fleet reached through a member's gate" do
      member = create(:user)
      create(:fleet_membership, :accepted, fleet: @fleet, user: member)
      Flipper.enable_actor("fleet_tours", member)
      @fleet.update_column(:discarded_at, Time.current)

      assert_empty Readiness.call[:gated_fleet_ids]
    end

    test "ignores a membership that was discarded" do
      member = create(:user)
      membership = create(:fleet_membership, :accepted, fleet: @fleet, user: member)
      Flipper.enable_actor("fleet_tours", member)
      membership.update_column(:discarded_at, Time.current)

      assert_empty Readiness.call[:gated_fleet_ids]
    end

    test "counts nobody when no gate is set at all" do
      readiness = Readiness.call

      assert_empty readiness[:gated_fleet_ids]
      assert_empty readiness[:unready_fleet_ids]
    end
  end
end
