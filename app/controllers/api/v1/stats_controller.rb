# frozen_string_literal: true

module Api
  module V1
    class StatsController < ::Api::V1::BaseController
      before_action :authenticate_api_user!, only: []

      def components_by_class
        authorize! :read, :api_stats

        components_by_class = transform_for_pie_chart(
          Component.group(:component_class).count
              .map { |label, count| { (label.present? ? I18n.t("filter.component.class.items.#{label.downcase}") : I18n.t('labels.unknown')) => count } }
              .reduce(:merge)
        )

        render json: components_by_class
      end

      def models_by_size
        authorize! :read, :api_stats

        models_by_size = transform_for_pie_chart(
          Model.group(:size).count
              .map { |label, count| { (label.present? ? label.humanize : I18n.t('labels.unknown')) => count } }
              .reduce(:merge)
        )

        render json: models_by_size.to_json
      end

      def models_by_production_status
        authorize! :read, :api_stats

        models_by_production_status = transform_for_pie_chart(
          Model.group(:production_status).count
              .map { |label, count| { (label.present? ? label.humanize : I18n.t('labels.unknown')) => count } }
              .reduce(:merge)
        )

        render json: models_by_production_status.to_json
      end

      def models_by_manufacturer
        authorize! :read, :api_stats

        models_by_manufacturer = transform_for_pie_chart(
          Manufacturer.with_model
                      .map { |m| { m.name => m.models.count } }
                      .reduce(:merge)
        )

        render json: models_by_manufacturer.to_json
      end

      def models_by_classification
        authorize! :read, :api_stats

        models_by_classification = transform_for_pie_chart(
          Model.group(:classification).count
              .map { |label, count| { (label.present? ? label.humanize : I18n.t('labels.unknown')) => count } }
              .reduce(:merge)
        )

        render json: models_by_classification.to_json
      end

      def models_per_month
        authorize! :stats, :admin

        models_per_month = Model.where('created_at > ?', Time.zone.now - 1.year)
                                .group_by_month(:created_at)
                                .count
                                .map do |created_at, count|
                                  {
                                    label: I18n.l(created_at.to_date, format: :month_year_short),
                                    count: count,
                                    tooltip: I18n.l(created_at.to_date, format: :month_year)
                                  }
                                end

        render json: models_per_month.to_json
      end

      private def transform_for_pie_chart(data)
        data.sort_by { |_label, count| count }.reverse
            .each_with_index.map do |(label, count), index|
              point = {
                name: label,
                y: count
              }
              if index.zero?
                point[:selected] = true
                point[:sliced] = true
              end
              point
            end
      end
    end
  end
end
