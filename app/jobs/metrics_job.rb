# frozen_string_literal: true

class MetricsJob < ApplicationJob
  def perform
    User.rollup("Registrations", interval: "month")
    User.rollup("Registrations", interval: "year")
    User.rollup("Activity", interval: "year", column: :last_active_at)
    User.rollup("Activity", interval: "month", column: :last_active_at)
    Model.visible.active.rollup("Models", interval: "month")
    Model.visible.active.rollup("Models", interval: "year")
    Fleet.rollup("Fleet", interval: "month")
    Fleet.rollup("Fleet", interval: "year")
    Vehicle.visible.purchased.where(loaner: false).rollup("Vehicle", interval: "year")
    Vehicle.visible.purchased.where(loaner: false).rollup("Vehicle", interval: "month")
    Vehicle.visible.wanted.where(loaner: false).rollup("Vehicle Wish", interval: "year")
    Vehicle.visible.wanted.where(loaner: false).rollup("Vehicle Wish", interval: "month")
  end
end
