# frozen_string_literal: true

require 'hangar_importer'

module Api
  module V2
    module Hangar
      class StatsController < ::Api::V2::BaseController
        include ChartHelper

        # rubocop:disable Metrics/CyclomaticComplexity
        def show
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

        def models_by_size
          authorize! :read, :api_stats

          models_by_size = transform_for_pie_chart(
            current_user.vehicles.visible.where(loaner: false)
                 .joins(:model)
                 .group('models.size').count
                 .map { |label, count| { (label.present? ? label.humanize : I18n.t('labels.unknown')) => count } }
                 .reduce(:merge) || []
          )

          render json: models_by_size.to_json
        end

        def models_by_production_status
          authorize! :read, :api_stats

          models_by_production_status = transform_for_pie_chart(
            current_user.vehicles.visible.where(loaner: false)
                 .joins(:model)
                 .group('models.production_status').count
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
                  { manufacturer.name => current_user.vehicles.visible.where(loaner: false, model_id: model_ids).count }
                end
                .reduce(:merge) || []
          )

          render json: models_by_manufacturer.to_json
        end

        def models_by_classification
          authorize! :read, :api_stats

          models_by_classification = transform_for_pie_chart(
            current_user.vehicles.visible.where(loaner: false)
                 .joins(:model)
                 .group('models.classification').count
                 .map { |label, count| { (label.present? ? label.humanize : I18n.t('labels.unknown')) => count } }
                 .reduce(:merge) || []
          )

          render json: models_by_classification.to_json
        end

        private def vehicle_query_params
          @vehicle_query_params ||= query_params(
            :name_cont, :model_name_or_model_description_cont, :on_sale_eq, :purchased_eq, :public_eq,
            :length_gteq, :length_lteq, :price_gteq, :price_lteq, :pledge_price_gteq,
            :pledge_price_lteq, :loaner_eq,
            manufacturer_in: [], classification_in: [], focus_in: [],
            size_in: [], price_in: [], pledge_price_in: [],
            production_status_in: [], hangar_groups_in: [], hangar_groups_not_in: []
          )
        end
      end
    end
  end
end
