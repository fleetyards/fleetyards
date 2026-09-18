# frozen_string_literal: true

require "test_helper"

module Maintenance
  class GraceBetaFleetsTaskTest < ActiveSupport::TestCase
    setup do
      @fleet = create(:fleet)
      Flipper.enable_actor("fleet_contracts", @fleet)
    end

    # An accidental run has to report rather than grant, so the safe mode is
    # the one you get by not choosing.
    test "dry_run is on unless it is turned off" do
      assert_predicate ::Maintenance::GraceBetaFleetsTask.new, :dry_run
    end

    test "a bare run writes nothing" do
      assert_no_difference -> { FleetSubscription.count } do
        run_task(dry_run: true)
      end
    end

    test "a bare run says what it would do" do
      output = run_task(dry_run: true)

      assert_match(/1 would be graced until/, output)
      assert_match(/#{Regexp.escape(@fleet.name)}/, output)
    end

    test "a wet run opens a dated grace subscription" do
      assert_difference -> { FleetSubscription.count }, 1 do
        run_task(dry_run: false)
      end

      subscription = FleetSubscription.sole

      assert_equal @fleet.id, subscription.fleet_id
      assert_predicate subscription, :granted_via_manual?
      assert_equal Date.current + 3.months, subscription.ended_at
      assert_match(/announcement/i, subscription.note)
    end

    test "the window closes by itself" do
      run_task(dry_run: false)

      assert_predicate @fleet.reload, :subscribed?
      travel_to(Date.current + 4.months) { refute_predicate @fleet.reload, :subscribed? }
    end

    test "a second run does not grant the same fleet twice" do
      run_task(dry_run: false)

      assert_no_difference -> { FleetSubscription.count } do
        run_task(dry_run: false)
      end
    end

    test "a fleet that already pays is left alone" do
      create(:fleet_subscription, fleet: @fleet, granted_via: "contribution")

      assert_no_difference -> { FleetSubscription.count } do
        run_task(dry_run: false)
      end
    end

    test "a member's personal gate graces the fleet they belong to" do
      other = create(:fleet)
      member = create(:user)
      create(:fleet_membership, :accepted, fleet: other, user: member)
      Flipper.enable_actor("fleet_tours", member)

      run_task(dry_run: false)

      assert_predicate other.reload, :subscribed?
    end

    # The reconciler closes rows it seeded from contributions. A grace row has
    # no contribution behind it and must survive a run.
    test "the reconciler leaves a grace subscription alone" do
      run_task(dry_run: false)

      ::Subscriptions::Sync.call

      assert_predicate @fleet.reload, :subscribed?
    end

    # A flag granting through anything that names no actors has a population
    # the gate list does not describe, so granting against it would cover a few
    # fleets and miss the rest.
    test "it refuses to grant while a premium flag is on for everybody" do
      Flipper.enable("fleet_logistics")

      assert_no_difference -> { FleetSubscription.count } do
        output = run_task(dry_run: false)

        assert_match(/STOP: fleet_logistics grants by boolean/, output)
      end
    end

    test "it refuses to grant while a premium flag grants to a percentage" do
      Flipper.enable_percentage_of_actors("fleet_tours", 50)

      assert_no_difference -> { FleetSubscription.count } do
        output = run_task(dry_run: false)

        assert_match(/STOP: fleet_tours grants by percentage_of_actors/, output)
      end
    end

    test "it refuses to grant while a premium flag grants to a group" do
      Flipper.enable_group("fleet_contracts", :testers)

      assert_no_difference -> { FleetSubscription.count } do
        run_task(dry_run: false)
      end
    end

    # A grace subscription for a deleted fleet is not a thing to create.
    test "a discarded fleet is not graced" do
      @fleet.update_column(:discarded_at, Time.current)

      assert_no_difference -> { FleetSubscription.count } do
        run_task(dry_run: false)
      end
    end

    # These rows carry an `ended_at`, so the partial unique index on open
    # subscriptions does not cover them and the database will not catch a
    # double grant. `grant` therefore takes no snapshot at all and reads the
    # population again inside the lock -- it cannot be handed a stale one.
    test "the grant reads the population again rather than trusting a snapshot" do
      run_task(dry_run: false)

      assert_no_difference -> { FleetSubscription.count } do
        task = ::Maintenance::GraceBetaFleetsTask.new
        task.dry_run = false
        capture_io { task.send(:grant) }
      end
    end

    test "the window length can be chosen" do
      run_task(dry_run: false, months: 6)

      assert_equal Date.current + 6.months, FleetSubscription.sole.ended_at
    end

    private def run_task(dry_run:, **attributes)
      task = ::Maintenance::GraceBetaFleetsTask.new
      task.dry_run = dry_run
      attributes.each { |name, value| task.public_send(:"#{name}=", value) }

      capture_io { task.process }.first
    end
  end
end
