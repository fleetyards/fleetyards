# frozen_string_literal: true

require "test_helper"

class SupporterMonthlyStatsTest < ActiveSupport::TestCase
  UNTIL_DATE = Date.new(2026, 8, 20)

  def build(**options)
    SupporterMonthlyStats.new(until_date: UNTIL_DATE, **options)
  end

  test "returns one entry per month, oldest first, ending in the until_date month" do
    entries = build.entries

    assert_equal 12, entries.size
    assert_equal Date.new(2025, 9, 1), entries.first.starts_on
    assert_equal Date.new(2026, 8, 1), entries.last.starts_on
    assert_equal entries.map(&:starts_on).sort, entries.map(&:starts_on)
  end

  test "honours a custom month count" do
    entries = build(months: 3).entries

    assert_equal 3, entries.size
    assert_equal Date.new(2026, 6, 1), entries.first.starts_on
  end

  test "counts a one-time contribution only in the month it started" do
    create(:supporter_contribution, amount_cents: 700, started_at: Date.new(2026, 6, 10))

    by_month = build.entries.to_h { |month| [month.starts_on, month] }

    assert_equal 700, by_month[Date.new(2026, 6, 1)].amount_cents
    assert_equal 1, by_month[Date.new(2026, 6, 1)].count
    assert_equal 0, by_month[Date.new(2026, 7, 1)].amount_cents
    assert_equal 0, by_month[Date.new(2026, 5, 1)].amount_cents
  end

  test "counts an ongoing recurring contribution in every month it spans" do
    create(:supporter_contribution, :recurring, amount_cents: 500, started_at: Date.new(2026, 6, 1))

    amounts = build.entries.to_h { |month| [month.starts_on, month.amount_cents] }

    assert_equal 0, amounts[Date.new(2026, 5, 1)]
    assert_equal 500, amounts[Date.new(2026, 6, 1)]
    assert_equal 500, amounts[Date.new(2026, 7, 1)]
    assert_equal 500, amounts[Date.new(2026, 8, 1)]
  end

  test "stops counting a recurring contribution after the month it ended in" do
    create(
      :supporter_contribution,
      :recurring,
      amount_cents: 500,
      started_at: Date.new(2026, 5, 1),
      ended_at: Date.new(2026, 6, 15)
    )

    amounts = build.entries.to_h { |month| [month.starts_on, month.amount_cents] }

    assert_equal 500, amounts[Date.new(2026, 5, 1)]
    assert_equal 500, amounts[Date.new(2026, 6, 1)]
    assert_equal 0, amounts[Date.new(2026, 7, 1)]
  end

  test "in-memory bucketing agrees with the active_in scope for every month" do
    create(:supporter_contribution, amount_cents: 100, started_at: Date.new(2026, 6, 10))
    create(:supporter_contribution, :recurring, amount_cents: 200, started_at: Date.new(2025, 12, 1))
    create(:supporter_contribution, :recurring, amount_cents: 400, started_at: Date.new(2026, 1, 1), ended_at: Date.new(2026, 6, 15))
    create(:supporter_contribution, amount_cents: 800, started_at: Date.new(2026, 8, 20))
    create(:supporter_contribution, :recurring, amount_cents: 1_600, started_at: Date.new(2024, 3, 1), ended_at: Date.new(2025, 10, 31))

    build.entries.each do |month|
      expected = SupporterContribution.active_in(month.starts_on, month.starts_on.end_of_month)

      assert_equal expected.sum(:amount_cents), month.amount_cents, "amount mismatch for #{month.starts_on}"
      assert_equal expected.count, month.count, "count mismatch for #{month.starts_on}"
    end
  end

  test "reports the goal that stood in each month" do
    create(:funding_goal, amount_cents: 6_000, effective_from: Date.new(2025, 1, 1), ended_at: Date.new(2026, 5, 31))
    create(:funding_goal, amount_cents: 9_000, effective_from: Date.new(2026, 6, 1))

    goals = build.entries.to_h { |month| [month.starts_on, month.goal_amount_cents] }

    assert_equal 6_000, goals[Date.new(2026, 5, 1)]
    assert_equal 9_000, goals[Date.new(2026, 6, 1)]
    assert_equal 9_000, goals[Date.new(2026, 8, 1)]
  end

  test "does not double count a goal replaced mid-month" do
    create(:funding_goal, amount_cents: 6_000, effective_from: Date.new(2025, 1, 1), ended_at: Date.new(2026, 6, 15))
    create(:funding_goal, amount_cents: 9_000, effective_from: Date.new(2026, 6, 16))

    goals = build.entries.to_h { |month| [month.starts_on, month.goal_amount_cents] }

    assert_equal 9_000, goals[Date.new(2026, 6, 1)]
  end

  test "the current month's goal matches what the public progress page reports" do
    create(:funding_goal, amount_cents: 6_000, effective_from: Date.new(2025, 1, 1), ended_at: UNTIL_DATE)
    create(:funding_goal, amount_cents: 1_000, effective_from: Date.new(2025, 1, 1))

    assert_equal FundingGoal.monthly_total(UNTIL_DATE), build.entries.last.goal_amount_cents
  end

  test "sums goals that run alongside each other" do
    create(:funding_goal, amount_cents: 6_000, effective_from: Date.new(2025, 1, 1))
    create(:funding_goal, amount_cents: 1_000, effective_from: Date.new(2025, 1, 1))

    assert_equal 7_000, build.entries.last.goal_amount_cents
  end

  test "restricts contributions to the given scope" do
    create(:supporter_contribution, :recurring, amount_cents: 500, started_at: Date.new(2026, 6, 1))
    create(:supporter_contribution, amount_cents: 900, started_at: Date.new(2026, 6, 10))

    entries = build(scope: SupporterContribution.where(recurring: true)).entries
    amounts = entries.to_h { |month| [month.starts_on, month.amount_cents] }

    assert_equal 500, amounts[Date.new(2026, 6, 1)]
  end

  test "falls back to EUR when there is nothing to read a currency from" do
    assert_equal "EUR", build.currency
  end

  test "reads the currency from the contributions in range" do
    create(:supporter_contribution, currency: "USD", started_at: Date.new(2026, 6, 10))

    assert_equal "USD", build.currency
  end
end
