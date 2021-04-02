# frozen_string_literal: true

module Api
  module V1
    class FleetStatsController < ::Api::BaseController
      include ChartHelper

      def models_by_size
        authorize! :show, fleet

        models_by_size = transform_for_pie_chart(
          fleet.models
               .group(:size).count
               .map { |label, count| { (label.present? ? label.humanize : I18n.t('labels.unknown')) => count } }
               .reduce(:merge) || []
        )

        render json: models_by_size.to_json
      end

      def models_by_production_status
        authorize! :show, fleet

        models_by_production_status = transform_for_pie_chart(
          fleet.models
               .group(:production_status).count
               .map { |label, count| { (label.present? ? label.humanize : I18n.t('labels.unknown')) => count } }
               .reduce(:merge) || []
        )

        render json: models_by_production_status.to_json
      end

      def models_by_manufacturer
        authorize! :show, fleet

        models_by_manufacturer = transform_for_pie_chart(
          fleet.manufacturers.uniq
              .map do |manufacturer|
                model_ids = manufacturer.model_ids
                { manufacturer.name => fleet.vehicles.where(model_id: model_ids).count }
              end
              .reduce(:merge) || []
        )

        render json: models_by_manufacturer.to_json
      end

      def models_by_classification
        authorize! :show, fleet

        models_by_classification = transform_for_pie_chart(
          fleet.models
               .group(:classification).count
               .map { |label, count| { (label.present? ? label.humanize : I18n.t('labels.unknown')) => count } }
               .reduce(:merge) || []
        )

        render json: models_by_classification.to_json
      end

      private def fleet
        @fleet ||= current_user.fleets.where(slug: params[:slug]).first!
      end
    end
  end
end
