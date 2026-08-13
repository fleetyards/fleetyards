# frozen_string_literal: true

class MetricsJob < ApplicationJob
  def perform
    User.rollup("Registrations", interval: "month")
    User.rollup("Registrations", interval: "year")
    User.rollup("Activity", interval: "year", column: :last_active_at)
    User.rollup("Activity", interval: "month", column: :last_active_at)
    User.rollup("Activity", interval: "week", column: :last_active_at)
    Model.visible.active.rollup("Models", interval: "month")
    Model.visible.active.rollup("Models", interval: "year")
    Fleet.rollup("Fleet", interval: "month")
    Fleet.rollup("Fleet", interval: "year")
    Vehicle.visible.purchased.where(loaner: false).rollup("Vehicle", interval: "year")
    Vehicle.visible.purchased.where(loaner: false).rollup("Vehicle", interval: "month")
    Vehicle.visible.wanted.where(loaner: false).rollup("Vehicle Wish", interval: "year")
    Vehicle.visible.wanted.where(loaner: false).rollup("Vehicle Wish", interval: "month")

    track_ship_of_the_month
    track_api_usage
  end

  private

  # Rolls up every day still held in Redis, not just yesterday, so a failed run
  # does not drop a day of counters.
  def track_api_usage
    applications = Oauth::Application.pluck(:id, :name)

    ApiUsageTracker.pending_days.each do |day|
      applications.each do |id, name|
        count = ApiUsageTracker.count(id, day)
        next if count.zero?

        dimensions = {application_id: id, application: name}

        Rollup.where(name: ApiUsageTracker::ROLLUP_NAME, interval: "day", time: day, dimensions:).delete_all
        Rollup.create!(
          name: ApiUsageTracker::ROLLUP_NAME,
          interval: "day",
          time: day,
          value: count,
          dimensions:
        )

        ApiUsageTracker.reset(id, day)
      end
    end
  end

  def track_ship_of_the_month
    month_start = Time.current.beginning_of_month

    ship = Vehicle.visible
      .where(loaner: false, wanted: false)
      .where(created_at: month_start..)
      .joins(:model)
      .group("models.name")
      .order(Arel.sql("count(*) DESC"))
      .limit(1)
      .count
      .first

    return unless ship

    Rollup.where(name: "Ship of the Month", interval: "month", time: month_start).delete_all
    Rollup.create!(
      name: "Ship of the Month",
      interval: "month",
      time: month_start,
      value: ship.last,
      dimensions: {name: ship.first}
    )
  end
end
