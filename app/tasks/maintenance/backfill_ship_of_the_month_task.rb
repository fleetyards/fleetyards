# frozen_string_literal: true

module Maintenance
  class BackfillShipOfTheMonthTask < MaintenanceTasks::Task
    no_collection

    def process
      12.times do |i|
        month_start = (Time.current - i.months).beginning_of_month
        month_end = month_start.end_of_month

        ship = Vehicle.visible
          .where(loaner: false, wanted: false)
          .where(created_at: month_start..month_end)
          .joins(:model)
          .group("models.name")
          .order(Arel.sql("count(*) DESC"))
          .limit(1)
          .count
          .first

        next unless ship

        Rollup.where(name: "Ship of the Month", interval: "month", time: month_start).delete_all
        Rollup.create!(
          name: "Ship of the Month",
          interval: "month",
          time: month_start,
          value: ship.last,
          dimensions: {name: ship.first}
        )

        Rails.logger.info("Ship of the Month - #{month_start.strftime("%B %Y")}: #{ship.first} (#{ship.last})")
      end
    end
  end
end
