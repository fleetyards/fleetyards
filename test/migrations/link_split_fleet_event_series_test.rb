# frozen_string_literal: true

require "test_helper"
require Rails.root.join("db/data/20261001120100_link_split_fleet_event_series.rb")

class LinkSplitFleetEventSeriesTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user)
    @fleet = create(:fleet, admins: [@admin])
  end

  def weekly(title, starts_at: Time.zone.parse("2026-05-14 20:00 UTC"), timezone: "Europe/Berlin", **attributes)
    create(:fleet_event, :open, fleet: @fleet, created_by: @admin, title:, starts_at:, timezone:,
      recurring: true, recurrence_interval: "weekly", recurrence_every: 1, **attributes)
  end

  def backfill
    ActiveRecord::Migration.suppress_messages { LinkSplitFleetEventSeries.new.up }
  end

  test "links a series split before the link was recorded" do
    series = weekly("Weekly Op")
    successor = FleetEvents::SeriesSplit.new(series, "2026-06-04").call
    successor.update_columns(split_from_id: nil)

    backfill

    assert_equal series.id, successor.reload.split_from_id
  end

  test "links nothing that only shares a title" do
    weekly("Weekly Op", recurrence_until: Date.parse("2026-05-31"))
    unrelated = weekly("Weekly Op", starts_at: Time.zone.parse("2026-06-11 20:00 UTC"))

    backfill

    assert_nil unrelated.reload.split_from_id
  end

  test "links nothing when two events could be the original" do
    weekly("Weekly Op", recurrence_until: Date.parse("2026-06-03"))
    weekly("Weekly Op", starts_at: Time.zone.parse("2026-05-07 20:00 UTC"), recurrence_until: Date.parse("2026-06-03"))
    successor = weekly("Weekly Op", starts_at: Time.zone.parse("2026-06-04 20:00 UTC"))

    backfill

    assert_nil successor.reload.split_from_id
  end

  # 21:00 in New York is 01:00 the next day in UTC; the split dates the
  # original's end by the local day.
  test "links a split whose first occurrence falls on another UTC day" do
    series = weekly("Evening Op", starts_at: Time.zone.parse("2026-05-15 01:00 UTC"), timezone: "America/New_York")
    successor = FleetEvents::SeriesSplit.new(series, "2026-06-05").call

    assert_equal Date.parse("2026-06-03"), series.reload.recurrence_until
    successor.update_columns(split_from_id: nil)

    backfill

    assert_equal series.id, successor.reload.split_from_id
  end

  test "links nothing that keeps another rhythm" do
    weekly("Weekly Op", recurrence_until: Date.parse("2026-06-03"))
    successor = weekly("Weekly Op", starts_at: Time.zone.parse("2026-06-04 20:00 UTC"), recurrence_interval: "monthly")

    backfill

    assert_nil successor.reload.split_from_id
  end
end
