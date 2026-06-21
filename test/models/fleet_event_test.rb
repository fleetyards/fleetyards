# frozen_string_literal: true

require "test_helper"

class FleetEventTest < ActiveSupport::TestCase
  class SignupsCountTest < FleetEventTest
    setup do
      @event = create(:fleet_event, :open)
      @team = create(:fleet_event_team, fleet_event: @event)
      @slot = create(:fleet_event_slot, slottable: @team)
      @fleet_membership = create(:fleet_membership, fleet: @event.fleet)
      @other_membership = create(:fleet_membership, fleet: @event.fleet)
    end

    test "counts slot-bound and unassigned signups together, ignoring withdrawn" do
      create(:fleet_event_signup, fleet_event: @event, fleet_event_slot: @slot, fleet_membership: @fleet_membership)
      create(:fleet_event_signup, fleet_event: @event, fleet_event_slot: nil, fleet_membership: @other_membership, status: "interested")
      withdrawn_member = create(:fleet_membership, fleet: @event.fleet)
      create(:fleet_event_signup, fleet_event: @event, fleet_event_slot: nil, fleet_membership: withdrawn_member, status: "withdrawn")

      assert_equal 2, @event.signups_count
    end
  end

  class PastTest < FleetEventTest
    test "is true when ends_at is in the past" do
      event = build(:fleet_event, starts_at: 2.hours.ago, ends_at: 1.hour.ago)
      assert event.past?
    end

    test "falls back to starts_at when ends_at is nil" do
      event = build(:fleet_event, starts_at: 1.hour.ago, ends_at: nil)
      assert event.past?
    end

    test "is false for upcoming events" do
      event = build(:fleet_event, starts_at: 1.day.from_now)
      refute event.past?
    end
  end

  class SignupsOpenTest < FleetEventTest
    test "is true when status is open and event is not past" do
      event = build(:fleet_event, :open, starts_at: 1.day.from_now)
      assert event.signups_open?
    end

    test "is false when status is open but the event already happened" do
      event = build(:fleet_event, :open, starts_at: 2.hours.ago, ends_at: 1.hour.ago)
      refute event.signups_open?
    end

    test "is false for non-open statuses" do
      %i[locked active cancelled].each do |trait|
        event = build(:fleet_event, trait, starts_at: 1.day.from_now)
        refute event.signups_open?, "expected #{trait} event to be closed"
      end
    end
  end

  class ArchiveTest < FleetEventTest
    test "round-trips archived_at" do
      event = create(:fleet_event)
      refute event.archived?
      event.archive!
      assert event.reload.archived?
      event.unarchive!
      refute event.reload.archived?
    end
  end

  class OccurrencesTest < FleetEventTest
    setup do
      @fleet = create(:fleet)
      @thursday = Time.zone.parse("2026-05-14 20:00:00 UTC")
    end

    test "returns just starts_at for a one-off event within the range" do
      event = create(:fleet_event, fleet: @fleet, starts_at: @thursday)

      assert_equal [@thursday],
        event.occurrences(from: @thursday - 1.day, to: @thursday + 1.day)
    end

    test "returns nothing for a one-off event outside the range" do
      event = create(:fleet_event, fleet: @fleet, starts_at: @thursday)

      assert_empty event.occurrences(from: @thursday + 1.day, to: @thursday + 7.days)
    end

    test "expands a weekly recurring event into successive occurrences" do
      event = create(:fleet_event,
        fleet: @fleet, starts_at: @thursday,
        recurring: true, recurrence_interval: "weekly")

      result = event.occurrences(from: @thursday, to: @thursday + 4.weeks)

      assert_equal 5, result.size
      assert_equal [4], result.map { |t| t.wday }.uniq
    end

    test "honours biweekly interval" do
      event = create(:fleet_event,
        fleet: @fleet, starts_at: @thursday,
        recurring: true, recurrence_interval: "biweekly")

      result = event.occurrences(from: @thursday, to: @thursday + 6.weeks)

      assert_equal 4, result.size
    end

    test "honours daily interval" do
      event = create(:fleet_event,
        fleet: @fleet, starts_at: @thursday,
        recurring: true, recurrence_interval: "daily")

      result = event.occurrences(from: @thursday, to: @thursday + 3.days)

      assert_equal 4, result.size
    end

    test "honours recurrence_until" do
      event = create(:fleet_event,
        fleet: @fleet, starts_at: @thursday,
        recurring: true, recurrence_interval: "weekly",
        recurrence_until: Date.parse("2026-05-28"))

      result = event.occurrences(from: @thursday, to: @thursday + 8.weeks)

      assert_equal 3, result.size
    end

    test "honours recurrence_count" do
      event = create(:fleet_event,
        fleet: @fleet, starts_at: @thursday,
        recurring: true, recurrence_interval: "weekly",
        recurrence_count: 4)

      result = event.occurrences(from: @thursday, to: @thursday + 8.weeks)

      assert_equal 4, result.size
    end

    test "honours excluded_dates" do
      event = create(:fleet_event,
        fleet: @fleet, starts_at: @thursday,
        recurring: true, recurrence_interval: "weekly",
        excluded_dates: [Date.parse("2026-05-21")])

      result = event.occurrences(from: @thursday, to: @thursday + 4.weeks)

      refute_includes result.map(&:to_date), Date.parse("2026-05-21")
      assert_equal 4, result.size
    end
  end

  class SkipOccurrenceTest < FleetEventTest
    test "appends the date to excluded_dates" do
      event = create(:fleet_event,
        starts_at: Time.zone.parse("2026-05-14 20:00:00 UTC"),
        recurring: true, recurrence_interval: "weekly")

      event.skip_occurrence!(Date.parse("2026-05-21"))

      assert_includes event.reload.excluded_dates, Date.parse("2026-05-21")
    end

    test "is idempotent for already-excluded dates" do
      event = create(:fleet_event,
        starts_at: Time.zone.parse("2026-05-14 20:00:00 UTC"),
        recurring: true, recurrence_interval: "weekly",
        excluded_dates: [Date.parse("2026-05-21")])

      before_size = event.excluded_dates.size
      event.skip_occurrence!(Date.parse("2026-05-21"))
      assert_equal before_size, event.reload.excluded_dates.size
    end
  end

  class EndSeriesAtTest < FleetEventTest
    test "sets recurrence_until to the day before the given date" do
      event = create(:fleet_event,
        starts_at: Time.zone.parse("2026-05-14 20:00:00 UTC"),
        recurring: true, recurrence_interval: "weekly")

      event.end_series_at!(Date.parse("2026-06-04"))

      assert_equal Date.parse("2026-06-03"), event.reload.recurrence_until
    end
  end

  class RecurringValidationTest < FleetEventTest
    test "requires recurrence_interval when recurring" do
      event = build(:fleet_event,
        recurring: true, recurrence_interval: nil)

      refute event.valid?
      assert event.errors[:recurrence_interval].present?
    end

    test "rejects recurrence_interval on non-recurring events" do
      event = build(:fleet_event,
        recurring: false, recurrence_interval: "weekly")

      refute event.valid?
      assert event.errors[:recurrence_interval].present?
    end

    test "rejects both recurrence_count and recurrence_until" do
      event = build(:fleet_event,
        recurring: true, recurrence_interval: "weekly",
        recurrence_count: 4, recurrence_until: Date.tomorrow)

      refute event.valid?
    end
  end
end
