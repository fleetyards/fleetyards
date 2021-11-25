# frozen_string_literal: true

module Api
  module V1
    class HangarStatsController < ::Api::BaseController
      include ChartHelper
      include HangarVehicles

      skip_authorization_check only: %i[public_index]
      before_action :authenticate_user!, except: %i[public_index]

      # rubocop:disable Metrics/CyclomaticComplexity
      def index
        authorize! :index, :api_hangar
        scope = current_user.vehicles.visible.includes(:vehicle_upgrades, :model_upgrades, :vehicle_modules, :model_modules, :model)

        scope = loaner_included?(scope)

        @q = scope.ransack(vehicle_query_params)

        @q.sorts = ['model_classification asc']

        vehicles = @q.result
        models = vehicles.map(&:model)
        upgrades = vehicles.map(&:model_upgrades).flatten
        modules = vehicles.map(&:model_modules).flatten

        @quick_stats = QuickStats.new(
          total: vehicles.count,
          classifications: Model.classifications.map do |classification|
            ClassificationCount.new(
              classification_count: models.count { |model| model.classification == classification },

              name: classification,
              label: classification.humanize
            )
          end,
          groups: HangarGroup.where(user: current_user).order([{ sort: :asc, name: :asc }]).map do |group|
            HangarGroupCount.new(
              group_count: group.vehicles.where(id: vehicles.map(&:id)).size,
              id: group.id,
              slug: group.slug
            )
          end,
          metrics: {
            total_money: models.map(&:last_pledge_price).sum(&:to_i) + modules.map(&:pledge_price).sum(&:to_i) + upgrades.map(&:pledge_price).sum(&:to_i),
            total_min_crew: models.map(&:min_crew).sum(&:to_i),
            total_max_crew: models.map(&:max_crew).sum(&:to_i),
            total_cargo: models.map(&:cargo).sum(&:to_i)
          }
        )
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def public_index
        user = User.find_by!('lower(username) = ?', params.fetch(:username, '').downcase)

        scope = user.vehicles
          .includes(:vehicle_upgrades, :model_upgrades, :vehicle_modules, :model_modules, :model)
          .public
          .where(loaner: false)

        @q = scope.ransack(vehicle_query_params)

        @q.sorts = ['model_classification asc']

        vehicles = @q.result

        models = vehicles.map(&:model)

        @quick_stats = QuickStats.new(
          total: vehicles.count,
          classifications: Model.classifications.map do |classification|
            ClassificationCount.new(
              classification_count: models.count { |model| model.classification == classification },

              name: classification,
              label: classification.humanize
            )
          end,
          groups: HangarGroup.where(user: user, public: true).order([{ sort: :asc, name: :asc }]).map do |group|
            HangarGroupCount.new(
              group_count: group.vehicles.where(id: vehicles.map(&:id)).size,
              id: group.id,
              slug: group.slug
            )
          end
        )
      end

      def models_by_size
        authorize! :read, :api_stats

        models_by_size = transform_for_pie_chart(
          current_user.models.visible.active
               .group(:size).count
               .map { |label, count| { (label.present? ? label.humanize : I18n.t('labels.unknown')) => count } }
               .reduce(:merge) || []
        )

        render json: models_by_size.to_json
      end

      def models_by_production_status
        authorize! :read, :api_stats

        models_by_production_status = transform_for_pie_chart(
          current_user.models.visible.active
               .group(:production_status).count
               .map { |label, count| { (label.present? ? label.humanize : I18n.t('labels.unknown')) => count } }
               .reduce(:merge) || []
        )

        render json: models_by_production_status.to_json
      end

      def models_by_manufacturer
        authorize! :read, :api_stats

        models_by_manufacturer = transform_for_pie_chart(
          current_user.manufacturers.uniq
              .map do |manufacturer|
                model_ids = manufacturer.model_ids
                { manufacturer.name => current_user.vehicles.where(model_id: model_ids).count }
              end
              .reduce(:merge) || []
        )

        render json: models_by_manufacturer.to_json
      end

      def models_by_classification
        authorize! :read, :api_stats

        models_by_classification = transform_for_pie_chart(
          current_user.models.visible.active
               .group(:classification).count
               .map { |label, count| { (label.present? ? label.humanize : I18n.t('labels.unknown')) => count } }
               .reduce(:merge) || []
        )

        render json: models_by_classification.to_json
      end
    end
  end
end
