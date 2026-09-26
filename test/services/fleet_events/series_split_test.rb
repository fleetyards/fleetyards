# frozen_string_literal: true

require "test_helper"

class FleetEvents::SeriesSplitTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user)
    @alice = create(:user)
    @fleet = create(:fleet, admins: [@admin], members: [@alice])
    @membership = @fleet.fleet_memberships.find_by!(user: @alice)
    @event = create(:fleet_event, :open,
      fleet: @fleet, created_by: @admin, title: "Weekly Op",
      starts_at: Time.zone.parse("2026-05-14 20:00:00 UTC"),
      ends_at: Time.zone.parse("2026-05-14 22:00:00 UTC"),
      timezone: "UTC",
      recurring: true, recurrence_interval: "weekly", recurrence_every: 1,
      excluded_dates: [Date.parse("2026-05-21"), Date.parse("2026-06-11")])
    @team = create(:fleet_event_team, fleet_event: @event, title: "Alpha")
    @ship = create(:fleet_event_ship, fleet_event_team: @team)
    @slot = create(:fleet_event_slot, slottable: @ship, title: "Pilot")
  end

  test "ends the series the day before and starts a copy on the occurrence" do
    successor = FleetEvents::SeriesSplit.new(@event, "2026-06-04").call

    assert_equal Date.parse("2026-06-03"), @event.reload.recurrence_until
    assert_equal Time.zone.parse("2026-06-04 20:00:00 UTC"), successor.starts_at
    assert_equal Time.zone.parse("2026-06-04 22:00:00 UTC"), successor.ends_at
    assert_equal ["Weekly Op", "open", "weekly", @admin.id],
      [successor.title, successor.status, successor.recurrence_interval, successor.created_by_id]
    assert_not_equal @event.slug, successor.slug
    assert_not_equal @event.external_uid, successor.external_uid
  end

  test "hands the later skipped dates to the copy" do
    successor = FleetEvents::SeriesSplit.new(@event, "2026-06-04").call

    assert_equal [Date.parse("2026-05-21")], @event.reload.excluded_dates
    assert_equal [Date.parse("2026-06-11")], successor.excluded_dates
  end

  test "copies the team, ship and slot tree" do
    successor = FleetEvents::SeriesSplit.new(@event, "2026-06-04").call

    team = successor.fleet_event_teams.sole
    assert_equal "Alpha", team.title
    assert_equal "Pilot", team.fleet_event_ships.sole.fleet_event_slots.sole.title
    assert_equal 1, @event.fleet_event_teams.count
  end

  test "moves later signups onto the copied slots and leaves earlier ones" do
    earlier = create(:fleet_event_signup, fleet_event_slot: @slot, fleet_membership: @membership,
      occurrence_date: Date.parse("2026-05-28"))
    later = create(:fleet_event_signup, fleet_event_slot: @slot, fleet_membership: @membership,
      occurrence_date: Date.parse("2026-06-18"))
    unassigned = FleetEventSignup.create!(fleet_event: @event, fleet_membership: @membership,
      status: "interested", occurrence_date: Date.parse("2026-06-04"))

    successor = FleetEvents::SeriesSplit.new(@event, "2026-06-04").call
    new_slot = successor.slots.sole

    assert_equal [@event.id, @slot.id], [earlier.reload.fleet_event_id, earlier.fleet_event_slot_id]
    assert_equal [successor.id, new_slot.id], [later.reload.fleet_event_id, later.fleet_event_slot_id]
    assert_equal [successor.id, nil], [unassigned.reload.fleet_event_id, unassigned.fleet_event_slot_id]
  end

  test "moves later occurrence overrides to the copy" do
    kept = create(:fleet_event_occurrence_state, fleet_event: @event, occurrence_date: Date.parse("2026-05-28"))
    moved = create(:fleet_event_occurrence_state, fleet_event: @event, occurrence_date: Date.parse("2026-06-04"),
      title: "Special", discord_event_id: "123")

    successor = FleetEvents::SeriesSplit.new(@event, "2026-06-04").call

    assert_equal @event.id, kept.reload.fleet_event_id
    assert_equal successor.id, moved.reload.fleet_event_id
  end

  test "carries the rest of a count-bounded series over" do
    @event.update!(recurrence_count: 6)

    successor = FleetEvents::SeriesSplit.new(@event, "2026-06-04").call

    assert_nil @event.reload.recurrence_count
    assert_equal 3, successor.recurrence_count
    assert_equal 6, @event.occurrences(from: @event.starts_at, to: 1.year.from_now(@event.starts_at), include_excluded: true).size +
      successor.occurrences(from: successor.starts_at, to: 1.year.from_now(successor.starts_at), include_excluded: true).size
  end

  test "keeps the weekday pattern of a custom interval" do
    @event.update!(starts_at: Time.zone.parse("2026-05-12 20:00:00 UTC"), recurrence_every: 2, recurrence_weekdays: [2, 4])

    successor = FleetEvents::SeriesSplit.new(@event, "2026-05-28").call

    assert_equal [2, 4], successor.recurrence_weekdays
    assert_equal 2, successor.recurrence_every
    assert_equal %w[2026-05-28 2026-06-09],
      successor.occurrences(from: successor.starts_at, to: Time.zone.parse("2026-06-10")).map { |t| t.to_date.iso8601 }
  end

  test "refuses a date the series has no occurrence on" do
    assert_raises(FleetEvents::SeriesSplit::NotAnOccurrence) do
      FleetEvents::SeriesSplit.new(@event, "2026-06-05").call
    end
  end

  test "refuses the first occurrence" do
    assert_raises(FleetEvents::SeriesSplit::AtSeriesStart) do
      FleetEvents::SeriesSplit.new(@event, "2026-05-14").call
    end
  end

  test "refuses a one-off event" do
    one_off = create(:fleet_event, fleet: @fleet)

    assert_raises(FleetEvents::SeriesSplit::NotRecurring) do
      FleetEvents::SeriesSplit.new(one_off, one_off.starts_at.to_date).call
    end
  end
end
