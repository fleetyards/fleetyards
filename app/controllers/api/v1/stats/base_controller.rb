# frozen_string_literal: true

module Api
  module V1
    module Stats
      class BaseController < Api::BaseController
        skip_verify_authorized

        include ChartHelper

        before_action :authenticate_user!, only: []

        def quick_stats
          models = Model.visible.active
          total = models.count
          flight_ready = models.where(production_status: "flight-ready").count
          pledge_prices = models.where("pledge_price > 0").pluck(:pledge_price)
          lengths = models.joins(:addition).where("model_additions.length > 0").pluck("model_additions.length")

          ship_of_the_month_entry = Rollup.where(
            name: "Ship of the Month",
            interval: "month",
            time: Time.current.beginning_of_month
          ).first

          @quick_stats = {
            ships_count_year: models.year(Time.current.year).count,
            ships_count_total: total,
            manufacturer_count: Manufacturer.with_model.count,
            flight_ready_count: flight_ready,
            average_pledge_price: pledge_prices.any? ? (pledge_prices.sum / pledge_prices.size).to_i : 0,
            largest_ship: lengths.max,
            smallest_ship: lengths.min,
            vehicles_count: Vehicle.where(loaner: false, wanted: false).count,
            wishlists_count: Vehicle.where(wanted: true).count,
            ship_of_the_month: ship_of_the_month_entry&.dimensions&.dig("name"),
            ship_of_the_month_count: ship_of_the_month_entry&.value&.to_i || 0
          }
        end

        def components_by_class
          components_by_class = transform_for_pie_chart(
            Component.group(:component_class).count
                .map { |label, count| {(label.present? ? I18n.t("filter.component.class.items.#{label.downcase}") : I18n.t("labels.unknown")) => count} }
                .reduce(:merge) || []
          )

          render json: components_by_class
        end

        def models_by_size
          models_by_size = transform_for_pie_chart(
            Model.visible.active
                 .group(:size).count
                 .map { |label, count| {(label.present? ? label.humanize : I18n.t("labels.unknown")) => count} }
                 .reduce(:merge) || []
          )

          render json: models_by_size.to_json
        end

        def models_by_production_status
          models_by_production_status = transform_for_pie_chart(
            Model.visible.active
                 .group(:production_status).count
                 .map { |label, count| {(label.present? ? label.humanize : I18n.t("labels.unknown")) => count} }
                 .reduce(:merge) || []
          )

          render json: models_by_production_status.to_json
        end

        def models_by_manufacturer
          models_by_manufacturer = transform_for_pie_chart(
            Manufacturer.with_model
                        .map { |m| {m.name => m.models.count} }
                        .reduce(:merge) || []
          )

          render json: models_by_manufacturer.to_json
        end

        def models_by_classification
          models_by_classification = transform_for_pie_chart(
            Model.visible.active
                 .group(:classification).count
                 .map { |label, count| {(label.present? ? label.humanize : I18n.t("labels.unknown")) => count} }
                 .reduce(:merge) || []
          )

          render json: models_by_classification.to_json
        end

        def vehicles_by_model
          vehicles_by_model = transform_for_bar_chart(
            Vehicle.visible.where(loaner: false, wanted: false)
                   .joins(:model)
                   .group("models.name").count
          ).take(10)

          render json: vehicles_by_model.to_json
        end

        def ships_of_the_month
          ships_of_the_month = Rollup
            .where(name: "Ship of the Month", interval: "month")
            .where("time > ?", 1.year.ago)
            .order(time: :desc)
            .map do |entry|
              {
                label: "#{entry.dimensions["name"]} (#{I18n.l(entry.time.to_date, format: :month_year_short)})",
                count: entry.value.to_i,
                tooltip: "#{entry.dimensions["name"]} (#{I18n.l(entry.time.to_date, format: :month_year)})"
              }
            end

          render json: ships_of_the_month.to_json
        end

        def vehicles_per_month
          vehicles_per_month = Rollup.where("time > ?", 1.year.ago).series("Vehicle", interval: :month).map do |created_at, count|
            {
              label: I18n.l(created_at.to_date, format: :month_year_short),
              count:,
              tooltip: I18n.l(created_at.to_date, format: :month_year)
            }
          end

          render json: vehicles_per_month.to_json
        end

        def models_per_month
          models_per_month = Rollup.where("time > ?", 1.year.ago).series("Models", interval: :month).map do |created_at, count|
            {
              label: I18n.l(created_at.to_date, format: :month_year_short),
              count:,
              tooltip: I18n.l(created_at.to_date, format: :month_year)
            }
          end

          render json: models_per_month.to_json
        end
      end
    end
  end
end
