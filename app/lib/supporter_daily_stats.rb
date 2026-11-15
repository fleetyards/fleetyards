# frozen_string_literal: true

# Builds the day-by-day running totals behind the admin supporter pace chart:
# how much had come in by each day of a month, for the current month and the
# ones before it, so a month in progress can be held against earlier months on
# the same day.
#
# A month counts the same contributions the monthly chart does, so a finished
# month's last value equals that month's column. A recurring contribution lands
# on its anniversary day, clamped to the month's length, or on the day it ended
# if that came first, so no money shows up after a cancellation.
#
# The current month also gets a projection from today to its last day: the
# recurring pledges still due this month on their anniversary days, which are
# already known, plus one-time contributions at a daily rate: the average over
# the earlier months, blended half and half with the same month a year before
# to carry its season. That month only counts once the one-time records in view
# reach back to its first day; before then it would read as a month nobody gave
# anything.
class SupporterDailyStats
  DEFAULT_MONTHS = 4
  DEFAULT_CURRENCY = "EUR"

  Month = Struct.new(:starts_on, :current, :days, :projection)

  def initialize(scope: SupporterContribution.all, months: DEFAULT_MONTHS, until_date: Date.current)
    @scope = scope
    @months = months
    @until_date = until_date
  end

  attr_reader :scope, :months, :until_date

  def entries
    @entries ||= month_starts.map do |month_start|
      current = month_start == until_date.beginning_of_month
      totals = running_totals(month_start)

      if current
        Month.new(starts_on: month_start, current:, days: totals.first(until_date.day), projection: projection(totals))
      else
        Month.new(starts_on: month_start, current:, days: totals, projection: [])
      end
    end
  end

  def goal_amount_cents
    FundingGoal.monthly_total(until_date)
  end

  def currency
    contributions.filter_map(&:currency).max ||
      FundingGoal.active_on(until_date).maximum(:currency) ||
      DEFAULT_CURRENCY
  end

  private def running_totals(month_start)
    month_end = month_start.end_of_month
    per_day = Array.new(month_end.day, 0)

    contributions.each do |contribution|
      next unless contribution.active_in?(month_start, month_end)

      per_day[landing_day(contribution, month_start, month_end) - 1] += contribution.amount_cents
    end

    total = 0
    per_day.map { |amount| total += amount }
  end

  # Starts on today with the actual total, so the projected line joins the
  # current month's line instead of floating beside it.
  private def projection(totals)
    totals.drop(until_date.day - 1).each_with_index.map do |scheduled, days_ahead|
      scheduled + (one_time_daily_rate * days_ahead).round
    end
  end

  private def one_time_daily_rate
    @one_time_daily_rate ||= begin
      rates = [recent_one_time_daily_rate, last_year_one_time_daily_rate].compact
      rates.empty? ? 0 : rates.sum / rates.size
    end
  end

  private def recent_one_time_daily_rate
    earlier = month_starts[...-1]
    return if earlier.empty?

    window = earlier.first..(until_date.beginning_of_month - 1.day)
    amount = contributions.reject(&:recurring?).select { |contribution| window.cover?(contribution.started_at) }.sum(&:amount_cents)

    amount.to_f / window.count
  end

  # Coverage is read from the one-time rows of the filtered scope: a pledge
  # running since long before says nothing about whether one-time payments
  # were recorded back then, and a start-date filter cuts the month off too.
  private def last_year_one_time_daily_rate
    month = until_date.prev_year.all_month
    first_on, amount = scope.where(recurring: false).pick(
      Arel.sql("MIN(supporter_contributions.started_at)"),
      Arel.sql(SupporterContribution.sanitize_sql_array([
        "COALESCE(SUM(supporter_contributions.amount_cents) FILTER (WHERE supporter_contributions.started_at BETWEEN ? AND ?), 0)",
        month.first, month.last
      ]))
    )
    return if first_on.nil? || first_on > month.first

    amount.to_f / month.count
  end

  private def landing_day(contribution, month_start, month_end)
    days = [contribution.started_at.day, month_end.day]
    days << contribution.ended_at.day if contribution.ended_at&.between?(month_start, month_end)
    days.min
  end

  private def month_starts
    (months - 1).downto(0).map { |back| until_date.beginning_of_month - back.months }
  end

  private def contributions
    @contributions ||= scope.active_in(month_starts.first, until_date.end_of_month).to_a
  end
end
