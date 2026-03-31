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
  end

  private

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
