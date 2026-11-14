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
class SupporterDailyStats
  DEFAULT_MONTHS = 4
  DEFAULT_CURRENCY = "EUR"

  Month = Struct.new(:starts_on, :current, :days)

  def initialize(scope: SupporterContribution.all, months: DEFAULT_MONTHS, until_date: Date.current)
    @scope = scope
    @months = months
    @until_date = until_date
  end

  attr_reader :scope, :months, :until_date

  def entries
    @entries ||= month_starts.map do |month_start|
      current = month_start == until_date.beginning_of_month
      last_day = current ? until_date.day : month_start.end_of_month.day

      Month.new(
        starts_on: month_start,
        current:,
        days: running_totals(month_start).first(last_day)
      )
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
