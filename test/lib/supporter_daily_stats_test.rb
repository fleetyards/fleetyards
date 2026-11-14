# frozen_string_literal: true

require "test_helper"

class SupporterDailyStatsTest < ActiveSupport::TestCase
  UNTIL_DATE = Date.new(2026, 8, 20)

  def build(**options)
    SupporterDailyStats.new(until_date: UNTIL_DATE, **options)
  end

  def by_month
    build.entries.to_h { |month| [month.starts_on, month] }
  end

  test "returns the until_date month and the three before it, oldest first" do
    entries = build.entries

    assert_equal [Date.new(2026, 5, 1), Date.new(2026, 6, 1), Date.new(2026, 7, 1), Date.new(2026, 8, 1)], entries.map(&:starts_on)
    assert_equal [false, false, false, true], entries.map(&:current)
  end

  test "has a value for every day of a past month and stops the current month at until_date" do
    months = by_month

    assert_equal 31, months[Date.new(2026, 5, 1)].days.size
    assert_equal 30, months[Date.new(2026, 6, 1)].days.size
    assert_equal 20, months[Date.new(2026, 8, 1)].days.size
  end

  test "accumulates a one-time contribution from the day it started" do
    create(:supporter_contribution, amount_cents: 700, started_at: Date.new(2026, 6, 10))

    days = by_month[Date.new(2026, 6, 1)].days

    assert_equal 0, days[8]
    assert_equal 700, days[9]
    assert_equal 700, days.last
    assert(by_month[Date.new(2026, 7, 1)].days.all?(&:zero?))
  end

  test "lands a recurring contribution on its anniversary day, clamped to the month's length" do
    create(:supporter_contribution, :recurring, amount_cents: 500, started_at: Date.new(2026, 3, 31))

    months = by_month

    assert_equal 0, months[Date.new(2026, 5, 1)].days[29]
    assert_equal 500, months[Date.new(2026, 5, 1)].days[30]
    assert_equal 0, months[Date.new(2026, 6, 1)].days[28]
    assert_equal 500, months[Date.new(2026, 6, 1)].days[29]
    assert(months[Date.new(2026, 8, 1)].days.all?(&:zero?))
  end

  test "lands a recurring contribution on the day it ended when that comes before its anniversary" do
    create(:supporter_contribution, :recurring, amount_cents: 500, started_at: Date.new(2026, 1, 20), ended_at: Date.new(2026, 8, 10))

    days = by_month[Date.new(2026, 8, 1)].days

    assert_equal 0, days[8]
    assert_equal 500, days[9]
    assert_equal 500, days[19]
  end

  test "falls back to the standing goal's currency without contributions" do
    create(:funding_goal, amount_cents: 9_000, currency: "USD", effective_from: Date.new(2026, 1, 1))

    assert_equal "USD", build.currency
  end

  test "a finished month ends at the monthly chart's total" do
    create(:supporter_contribution, amount_cents: 100, started_at: Date.new(2026, 6, 10))
    create(:supporter_contribution, :recurring, amount_cents: 200, started_at: Date.new(2025, 12, 28))
    create(:supporter_contribution, :recurring, amount_cents: 400, started_at: Date.new(2026, 1, 20), ended_at: Date.new(2026, 6, 15))
    create(:supporter_contribution, amount_cents: 800, started_at: Date.new(2026, 8, 20))

    monthly = SupporterMonthlyStats.new(until_date: UNTIL_DATE, months: 4).entries.to_h { |month| [month.starts_on, month.amount_cents] }

    build.entries.each do |month|
      assert_equal monthly[month.starts_on], month.days.last, "total mismatch for #{month.starts_on}" unless month.current
    end
    assert_equal 800, by_month[Date.new(2026, 8, 1)].days.last, "the recurring 200 lands on the 28th, after until_date"
  end

  test "reads the goal standing on until_date" do
    create(:funding_goal, amount_cents: 9_000, effective_from: Date.new(2026, 1, 1))
    create(:funding_goal, amount_cents: 5_000, effective_from: Date.new(2025, 1, 1), ended_at: Date.new(2025, 12, 31))

    assert_equal 9_000, build.goal_amount_cents
  end
end
