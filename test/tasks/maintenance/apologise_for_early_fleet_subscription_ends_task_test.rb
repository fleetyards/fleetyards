# frozen_string_literal: true

require "test_helper"

module Maintenance
  class ApologiseForEarlyFleetSubscriptionEndsTaskTest < ActiveSupport::TestCase
    setup do
      membership = create(:fleet_membership, :accepted)
      @fleet = membership.fleet
      @supporter = membership.user
      @admin = create(:user)
      create(:fleet_membership, fleet: @fleet, user: @admin, aasm_state: :accepted,
        fleet_role: @fleet.fleet_roles.ranked.first)
    end

    # The bug: a donation from 16 October was dropped on 1 November.
    private def close_early
      travel_to Date.new(2026, 10, 16) do
        create(:supporter_contribution, user: @supporter, fleet: @fleet,
          amount_cents: ::Subscriptions.qualifying_amount_cents, started_at: Date.current)
        ::Subscriptions::Sync.call
      end

      subscription = @fleet.fleet_subscriptions.sole

      travel_to Date.new(2026, 11, 1) do
        subscription.update!(ended_at: Date.current)
        ::Subscriptions::Notifier.ended(subscription, cause: :contribution)
      end

      subscription
    end

    private def apologies
      ::Notification.where(notification_type: "fleet_subscription_started", user: @admin)
        .where("title LIKE ?", "Sorry%")
    end

    private def run_task(dry_run:)
      task = ::Maintenance::ApologiseForEarlyFleetSubscriptionEndsTask.new
      task.dry_run = dry_run

      capture_io { task.process }.first
    end

    test "dry_run is on unless it is turned off" do
      assert_predicate ::Maintenance::ApologiseForEarlyFleetSubscriptionEndsTask.new, :dry_run
    end

    test "a dry run reports and changes nothing" do
      subscription = close_early

      travel_to Date.new(2026, 11, 2) do
        output = run_task(dry_run: true)

        assert_match(/1 early closures, 1 apologies, 1 reopened/, output)
      end

      assert_empty apologies
      assert_equal Date.new(2026, 11, 1), subscription.reload.ended_at
    end

    # A notification broadcasts when it is created, so a rolled-back one would
    # still reach an open tab.
    test "a dry run creates no notification at all" do
      close_early

      travel_to Date.new(2026, 11, 2) do
        assert_no_difference -> { ::Notification.count } do
          run_task(dry_run: true)
        end
      end
    end

    test "an admin reopening the same row does not count as an apology" do
      subscription = close_early

      travel_to Date.new(2026, 11, 2) do
        subscription.update!(ended_at: nil)
        ::Subscriptions::Notifier.started(subscription)
        run_task(dry_run: false)
      end

      assert_equal 1, apologies.count
    end

    # The reconciler runs daily and after every Ko-fi payment, so a failed run
    # on the 1st leaves the closure to a later day.
    test "a closure after the 1st is corrected too" do
      travel_to Date.new(2026, 10, 16) do
        create(:supporter_contribution, user: @supporter, fleet: @fleet,
          amount_cents: ::Subscriptions.qualifying_amount_cents, started_at: Date.current)
        ::Subscriptions::Sync.call
      end

      subscription = @fleet.fleet_subscriptions.sole

      travel_to Date.new(2026, 11, 2) do
        subscription.update!(ended_at: Date.current)
        ::Subscriptions::Notifier.ended(subscription, cause: :contribution)
      end

      travel_to(Date.new(2026, 11, 3)) { run_task(dry_run: false) }

      assert subscription.reload.open?
      assert_equal 1, apologies.count
    end

    test "an administrator ending the grant earns no apology" do
      subscription = close_early
      ::Notification.where(notification_type: "fleet_subscription_ended").delete_all

      travel_to Date.new(2026, 11, 1) do
        ::Subscriptions::Notifier.ended(subscription, cause: :manual)
      end

      travel_to(Date.new(2026, 11, 2)) { run_task(dry_run: false) }

      assert_empty apologies
      assert_equal Date.new(2026, 11, 1), subscription.reload.ended_at
    end

    test "a genuine lapse after an early one is not excused with it" do
      subscription = close_early

      travel_to(Date.new(2026, 11, 2)) { run_task(dry_run: false) }

      travel_to Date.new(2026, 11, 20) do
        assert_equal [subscription.id], ::Subscriptions::Sync.call[:closed].map(&:id)
      end

      travel_to(Date.new(2026, 11, 21)) { run_task(dry_run: false) }

      assert_equal 1, apologies.count
      assert_equal Date.new(2026, 11, 20), subscription.reload.ended_at
    end

    test "a recipient who switched language is not apologised to twice" do
      close_early

      travel_to(Date.new(2026, 11, 2)) { run_task(dry_run: false) }
      @admin.update_columns(locale: "de")
      travel_to(Date.new(2026, 11, 3)) { run_task(dry_run: false) }

      assert_equal 1, ::Notification.where(notification_type: "fleet_subscription_started", user: @admin)
        .where.not(title: nil).where("created_at > ?", Date.new(2026, 11, 1)).count
    end

    test "a donation nominated again after the closure earns no apology" do
      subscription = close_early

      travel_to Date.new(2026, 11, 2) do
        SupporterContribution.sole.update!(note: "nominated again")
        run_task(dry_run: false)
      end

      assert_empty apologies
      assert_equal Date.new(2026, 11, 1), subscription.reload.ended_at
    end

    test "a subscription ended while still covered is reopened and its recipients get an apology" do
      subscription = close_early

      travel_to Date.new(2026, 11, 2) do
        run_task(dry_run: false)
      end

      assert subscription.reload.open?
      apology = apologies.sole
      assert_equal subscription, apology.record
      assert_includes apology.title, @fleet.name
      assert_equal 1, @fleet.fleet_subscriptions.count, "the same row, not a new one"
    end

    test "a run after the reconciler has already reopened the fleet still apologises" do
      subscription = close_early

      travel_to Date.new(2026, 11, 2) do
        ::Subscriptions::Sync.call
        run_task(dry_run: false)
      end

      assert_equal Date.new(2026, 11, 1), subscription.reload.ended_at
      assert_equal 1, apologies.count
    end

    test "a second run sends nothing more" do
      close_early

      travel_to Date.new(2026, 11, 2) do
        run_task(dry_run: false)
        run_task(dry_run: false)
      end

      assert_equal 1, apologies.count
    end

    test "a subscription that ended once its donation had really lapsed is left alone" do
      travel_to Date.new(2026, 9, 1) do
        create(:supporter_contribution, user: @supporter, fleet: @fleet,
          amount_cents: ::Subscriptions.qualifying_amount_cents, started_at: Date.current)
        ::Subscriptions::Sync.call
      end

      subscription = @fleet.fleet_subscriptions.sole

      travel_to Date.new(2026, 10, 15) do
        assert_equal 1, ::Subscriptions::Sync.call[:closed].size
        run_task(dry_run: false)
      end

      assert_equal Date.new(2026, 10, 15), subscription.reload.ended_at
      assert_empty apologies
    end
  end
end
