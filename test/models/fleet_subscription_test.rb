# frozen_string_literal: true

require "test_helper"

class FleetSubscriptionTest < ActiveSupport::TestCase
  # The index, not a validation: two requests racing both pass a validation and
  # both write, and the second one is the bug nobody sees until it happens.
  test "a second open subscription for one fleet is refused by the database" do
    fleet = create(:fleet)
    create(:fleet_subscription, fleet:)

    assert_raises ActiveRecord::RecordNotUnique do
      FleetSubscription.create!(fleet:, started_at: Date.current)
    end
  end

  test "a closed subscription does not block a new one" do
    fleet = create(:fleet)
    create(:fleet_subscription, fleet:, started_at: 2.months.ago.to_date, ended_at: 1.month.ago.to_date)

    assert_nothing_raised do
      create(:fleet_subscription, fleet:)
    end
  end

  test "two fleets may each hold an open subscription" do
    create(:fleet_subscription)

    assert_nothing_raised { create(:fleet_subscription) }
  end

  test "active_on covers the open, closed, future and same-day boundaries" do
    today = Date.new(2026, 6, 15)

    open_today = create(:fleet_subscription, started_at: today)
    started_earlier = create(:fleet_subscription, started_at: today - 30)
    ends_today = create(:fleet_subscription, started_at: today - 30, ended_at: today)
    ended_yesterday = create(:fleet_subscription, started_at: today - 30, ended_at: today - 1)
    starts_tomorrow = create(:fleet_subscription, started_at: today + 1)

    active = FleetSubscription.active_on(today).pluck(:id)

    assert_includes active, open_today.id, "a subscription starting today covers today"
    assert_includes active, started_earlier.id
    assert_includes active, ends_today.id, "a subscription ending today still did"
    refute_includes active, ended_yesterday.id
    refute_includes active, starts_tomorrow.id
  end

  test "active_on? answers the same question as the scope" do
    today = Date.new(2026, 6, 15)

    [
      [create(:fleet_subscription, started_at: today), true],
      [create(:fleet_subscription, started_at: today - 30, ended_at: today), true],
      [create(:fleet_subscription, started_at: today - 30, ended_at: today - 1), false],
      [create(:fleet_subscription, started_at: today + 1), false]
    ].each do |subscription, expected|
      assert_equal expected, subscription.active_on?(today),
        "#{subscription.started_at}..#{subscription.ended_at.inspect}"
      assert_equal expected, FleetSubscription.active_on(today).exists?(id: subscription.id),
        "scope and predicate disagree for #{subscription.started_at}..#{subscription.ended_at.inspect}"
    end
  end

  test "ended_at may not precede started_at" do
    subscription = build(:fleet_subscription, started_at: Date.new(2026, 6, 1), ended_at: Date.new(2026, 5, 1))

    refute subscription.valid?
    assert_includes subscription.errors[:ended_at],
      subscription.errors.generate_message(:ended_at, :must_be_after_started_at)
  end

  # `seeded` is what D9's reconciler keys on: it closes only what it opened, so
  # a comp survives a sync that knows nothing about it.
  test "seeded finds only subscriptions with a contribution behind them" do
    seeded = create(:fleet_subscription, :seeded)
    comped = create(:fleet_subscription)

    ids = FleetSubscription.seeded.pluck(:id)

    assert_includes ids, seeded.id
    refute_includes ids, comped.id
  end

  test "a grant is manual unless it says otherwise" do
    assert_equal "manual", create(:fleet_subscription).granted_via
    assert create(:fleet_subscription).granted_via_manual?
    assert create(:fleet_subscription, :seeded).granted_via_contribution?
  end

  # A contribution can be deleted; the subscription it seeded must survive that
  # and stay identifiable as something the reconciler opened.
  test "deleting the contribution leaves the subscription and its provenance" do
    subscription = create(:fleet_subscription, :seeded)

    subscription.supporter_contribution.destroy!

    assert_nil subscription.reload.supporter_contribution_id
    assert subscription.granted_via_contribution?,
      "provenance must survive, or a seeded row becomes indistinguishable from a comp"
  end

  test "deleting the fleet takes its subscriptions with it rather than blocking" do
    subscription = create(:fleet_subscription)
    fleet = subscription.fleet

    assert_nothing_raised { fleet.destroy! }
    refute FleetSubscription.exists?(subscription.id)
  end

  test "an admin action records who granted or ended it" do
    subscription = create(:fleet_subscription)
    admin = create(:user)

    subscription.author_id = admin.id
    subscription.update!(ended_at: Date.current)

    version = subscription.versions.last

    assert_includes version.object_changes.keys, "ended_at"
    assert_equal admin.id, version.author_id
  end

  test "it is a versioned root authorised through its fleet" do
    assert_equal [:fleet], VersionedItem::ROOTS["FleetSubscription"]
  end
end
