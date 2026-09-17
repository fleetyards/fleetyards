# frozen_string_literal: true

require "test_helper"

module Subscriptions
  class SyncTest < ActiveSupport::TestCase
    setup do
      @membership = create(:fleet_membership, :accepted)
      @supporter = @membership.user
      @fleet = @membership.fleet
    end

    # `ranked.first` is the admin role, which is how the fleet factory makes one.
    private def admin_of(fleet)
      user = create(:user)
      create(:fleet_membership, fleet:, user:, aasm_state: :accepted,
        fleet_role: fleet.fleet_roles.ranked.first)
      user
    end

    private def nominated(amount_cents: Subscriptions.qualifying_amount_cents, fleet: @fleet, **attrs)
      create(:supporter_contribution, user: @supporter, fleet:, amount_cents:, **attrs)
    end

    test "an active, nominated, qualifying contribution opens a subscription" do
      contribution = nominated

      result = Sync.call

      subscription = @fleet.fleet_subscriptions.sole

      assert_equal [subscription], result[:opened]
      assert subscription.open?
      assert subscription.granted_via_contribution?
      assert_equal contribution.id, subscription.supporter_contribution_id
      assert_equal Date.current, subscription.started_at
    end

    test "a contribution below the figure opens nothing" do
      nominated(amount_cents: Subscriptions.qualifying_amount_cents - 1)

      Sync.call

      assert_empty FleetSubscription.all
    end

    test "an un-nominated contribution opens nothing however much it is for" do
      create(:supporter_contribution, user: @supporter, fleet: nil,
        amount_cents: Subscriptions.qualifying_amount_cents * 100)

      Sync.call

      assert_empty FleetSubscription.all
    end

    test "a contribution that is not active this month opens nothing" do
      nominated(started_at: Date.current.prev_month.beginning_of_month, recurring: false)

      Sync.call

      assert_empty FleetSubscription.all
    end

    # `ended_at`, never destroyed: the history is the table.
    test "when the contribution lapses the subscription it seeded is closed" do
      contribution = nominated
      Sync.call
      subscription = @fleet.fleet_subscriptions.sole

      contribution.update!(started_at: Date.current.prev_month.beginning_of_month)
      result = Sync.call

      assert_equal [subscription.id], result[:closed].map(&:id)
      assert_equal Date.current, subscription.reload.ended_at
      assert FleetSubscription.exists?(subscription.id), "closed, not destroyed"
    end

    test "clearing the nomination closes the subscription it seeded" do
      contribution = nominated
      Sync.call

      contribution.update!(fleet: nil)
      Sync.call

      assert_equal Date.current, @fleet.fleet_subscriptions.sole.reload.ended_at
    end

    # Every comp in #4958 depends on this.
    test "a manual subscription is untouched by a sync that would otherwise close it" do
      comp = create(:fleet_subscription, fleet: @fleet, granted_via: "manual")

      Sync.call

      assert_nil comp.reload.ended_at
      assert comp.open?
    end

    test "a manual subscription is never closed whatever its contribution says" do
      contribution = nominated
      comp = create(:fleet_subscription, fleet: @fleet, granted_via: "manual",
        supporter_contribution: contribution)

      contribution.update!(fleet: nil)
      Sync.call

      assert_nil comp.reload.ended_at,
        "provenance decides, not whether a contribution happens to be attached"
    end

    # The contribution can be deleted; the row stays identifiable as seeded and
    # therefore closeable, which is what the `seeded` scope exists for.
    test "a seeded subscription whose contribution was deleted is closed" do
      contribution = nominated
      Sync.call
      subscription = @fleet.fleet_subscriptions.sole

      contribution.destroy!
      Sync.call

      assert_equal Date.current, subscription.reload.ended_at
    end

    test "re-pointing a nomination closes the old fleet and opens the new one in one run" do
      other = create(:fleet_membership, :accepted, user: @supporter).fleet
      contribution = nominated
      Sync.call
      first = @fleet.fleet_subscriptions.sole

      contribution.update!(fleet: other)
      result = Sync.call

      assert_equal Date.current, first.reload.ended_at, "the old fleet's closed"
      assert_equal 1, result[:opened].size
      assert_equal other.id, result[:opened].sole.fleet_id
      assert other.fleet_subscriptions.sole.open?
    end

    test "a second run over unchanged data writes nothing" do
      nominated
      Sync.call

      before = FleetSubscription.order(:id).pluck(:id, :started_at, :ended_at, :updated_at)
      result = Sync.call

      assert_empty result[:opened]
      assert_empty result[:closed]
      assert_equal before, FleetSubscription.order(:id).pluck(:id, :started_at, :ended_at, :updated_at)
    end

    test "a fleet that already has an open subscription does not get a second one" do
      create(:fleet_subscription, fleet: @fleet, granted_via: "manual")
      nominated

      assert_nothing_raised { Sync.call }

      assert_equal 1, @fleet.fleet_subscriptions.count
    end

    test "two contributions naming one fleet open a single subscription" do
      nominated
      nominated(amount_cents: Subscriptions.qualifying_amount_cents * 2)

      Sync.call

      assert_equal 1, @fleet.fleet_subscriptions.count
    end

    # One contribution lapsing must not close a fleet another still entitles.
    test "a fleet stays subscribed while any contribution still entitles it" do
      lapsing = nominated
      nominated

      Sync.call
      lapsing.update!(fleet: nil)
      Sync.call

      assert @fleet.fleet_subscriptions.sole.open?
    end

    test "a standing pledge keeps the subscription open month after month" do
      nominated(recurring: true, started_at: Date.current.prev_month)
      Sync.call
      subscription = @fleet.fleet_subscriptions.sole

      travel_to Date.current.next_month do
        Sync.call
      end

      assert subscription.reload.open?, "a recurring pledge must not lapse across a month boundary"
    end

    test "each fleet is reconciled independently" do
      other_membership = create(:fleet_membership, :accepted)
      nominated
      create(:supporter_contribution, user: other_membership.user, fleet: other_membership.fleet,
        amount_cents: Subscriptions.qualifying_amount_cents)

      result = Sync.call

      assert_equal 2, result[:opened].size
      assert @fleet.fleet_subscriptions.sole.open?
      assert other_membership.fleet.fleet_subscriptions.sole.open?
    end

    # Without serialization two runs interleave: one snapshots a nomination,
    # a request clears it, and the first still opens a subscription nothing
    # entitles. The unique index cannot catch that -- a stale decision is a
    # well-formed row.
    test "reconciliation happens under one lock" do
      ActiveRecord::Base.expects(:with_advisory_lock).with(Sync::LOCK).once.yields

      Sync.call
    end

    # A run that gave up on the lock would leave exactly the state it was
    # enqueued to correct.
    test "a second run waits rather than skipping" do
      nominated

      first = Sync.call
      second = Sync.call

      assert_equal 1, first[:opened].size
      assert_empty second[:opened], "the second run saw the first's write"
    end

    # D14: the fleet is told before anybody meets a refusal, which means the
    # notification is sent where the subscription is written.
    test "opening a subscription tells the fleet's admins" do
      admin = admin_of(@fleet)
      nominated

      Sync.call

      assert Notification.exists?(user: admin, notification_type: "fleet_subscription_started")
    end

    test "closing one tells them too" do
      admin_of(@fleet)
      contribution = nominated
      Sync.call
      Notification.delete_all

      contribution.update!(fleet: nil)
      Sync.call

      assert Notification.exists?(notification_type: "fleet_subscription_ended")
    end

    test "a run that changes nothing tells nobody" do
      nominated
      Sync.call
      Notification.delete_all

      Sync.call

      assert_empty Notification.all, "a no-op sync must not re-announce anything"
    end
  end
end
