# frozen_string_literal: true

# Builds the month-by-month series behind the admin supporter chart: what was
# actually coming in each month, against the funding goal that stood at the
# time. Both sides are loaded once and bucketed in Ruby rather than queried per
# month, because a recurring contribution belongs to every month it spans.
class SupporterMonthlyStats
  DEFAULT_MONTHS = 12
  DEFAULT_CURRENCY = "EUR"

  Month = Struct.new(:starts_on, :amount_cents, :goal_amount_cents, :count)

  def initialize(scope: SupporterContribution.all, months: DEFAULT_MONTHS, until_date: Date.current)
    @scope = scope
    @months = months
    @until_date = until_date
  end

  attr_reader :scope, :months, :until_date

  def entries
    @entries ||= month_starts.map do |month_start|
      month_end = month_start.end_of_month
      active = contributions.select { |contribution| active_in?(contribution, month_start, month_end) }

      Month.new(
        starts_on: month_start,
        amount_cents: active.sum(&:amount_cents),
        goal_amount_cents: goal_amount_cents_on(goal_date_for(month_end)),
        count: active.size
      )
    end
  end

  def currency
    contributions.filter_map(&:currency).max ||
      goals.filter_map(&:currency).max ||
      DEFAULT_CURRENCY
  end

  private def month_starts
    (months - 1).downto(0).map { |back| until_date.beginning_of_month - back.months }
  end

  private def window_start
    @window_start ||= month_starts.first
  end

  private def window_end
    @window_end ||= until_date.end_of_month
  end

  private def contributions
    @contributions ||= scope.active_in(window_start, window_end).to_a
  end

  # Mirrors SupporterContribution.active_in for a single record.
  private def active_in?(contribution, month_start, month_end)
    return contribution.started_at.between?(month_start, month_end) unless contribution.recurring?

    contribution.started_at <= month_end &&
      (contribution.ended_at.nil? || contribution.ended_at >= month_start)
  end

  private def goals
    @goals ||= FundingGoal.where(effective_from: ..window_end)
      .where("ended_at IS NULL OR ended_at >= ?", window_start)
      .to_a
  end

  # Each month is measured on one day rather than over the whole range: a goal
  # replaced mid-month overlaps its successor, and summing both would double
  # that month's target. Clamping to today keeps the current month in step with
  # the public progress page, which reads the goals active right now.
  private def goal_date_for(month_end)
    [month_end, until_date].min
  end

  private def goal_amount_cents_on(date)
    goals.sum do |goal|
      next 0 unless goal.effective_from <= date
      next 0 unless goal.ended_at.nil? || goal.ended_at >= date

      goal.amount_cents
    end
  end
end
