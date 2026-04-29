# frozen_string_literal: true

module Api
  module V1
    class HangarStatsController < ::Api::BaseController
      include HangarFiltersConcern
      include ChartHelper

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?

      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def show
        authorize! with: ::HangarPolicy

        scope = authorized_scope(Vehicle.all).visible.purchased.includes(:vehicle_upgrades, :model_upgrades, :vehicle_modules, :model_modules, :model)

        scope = loaner_included?(scope)
        scope = will_it_fit?(scope) if vehicle_query_params["will_it_fit"].present?

        @q = scope.ransack(vehicle_query_params)

        @q.sorts = ["model_classification asc"]

        vehicles = @q.result
        ingame_vehicles = vehicles.select(&:bought_via_ingame?)
        pledge_store_vehicles = vehicles.select(&:bought_via_pledge_store?)
        models = vehicles.map(&:model)
        non_loaner_models = vehicles.reject(&:loaner?).map(&:model)
        pledge_store_models = pledge_store_vehicles.filter_map do |vehicle|
          vehicle.model unless vehicle.loaner?
        end
        ingame_models = ingame_vehicles.map(&:model)
        upgrades = vehicles.map(&:model_upgrades)
        upgrades.flatten!
        modules = vehicles.map(&:model_modules)
        modules.flatten!

        group_count_vehicle_ids = scope.ransack(vehicle_query_params.except("hangar_groups_in", "hangar_groups_not_in")).result.ids

        wishlist_scope = authorized_scope(Vehicle.all).visible.wanted.where(loaner: false)
        wishlist_vehicles = wishlist_scope.includes(:model).map(&:model)

        @quick_stats = QuickStats.new(
          total: vehicles.count,
          wishlist_total: wishlist_scope.count,
          classifications: Model.classifications.map do |classification|
            ClassificationCount.new(
              classification_count: models.count { |model| model.classification == classification },

              name: classification,
              label: classification.humanize
            )
          end,
          groups: HangarGroup.where(user: current_user).order([{sort: :asc, name: :asc}]).map do |group|
            HangarGroupCount.new(
              group_count: group.vehicles.where(id: group_count_vehicle_ids).size,
              id: group.id,
              slug: group.slug
            )
          end,
          metrics: hangar_metrics(models, non_loaner_models, pledge_store_models, ingame_models, modules, upgrades, wishlist_vehicles)
        )
      end
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/CyclomaticComplexity

      def models_by_size
        authorize! to: :show?, with: ::HangarPolicy

        models_by_size = transform_for_pie_chart(
          authorized_scope(Vehicle.all).visible.purchased.where(loaner: false)
               .joins(:model)
               .group("models.size").count
               .map { |label, count| {(label.present? ? label.humanize : I18n.t("labels.unknown")) => count} }
               .reduce(:merge) || []
        )

        render json: models_by_size.to_json
      end

      def models_by_production_status
        authorize! to: :show?, with: ::HangarPolicy

        models_by_production_status = transform_for_pie_chart(
          authorized_scope(Vehicle.all).visible.purchased.where(loaner: false)
               .joins(:model)
               .group("models.production_status").count
               .map { |label, count| {(label.present? ? label.humanize : I18n.t("labels.unknown")) => count} }
               .reduce(:merge) || []
        )

        render json: models_by_production_status.to_json
      end

      def models_by_manufacturer
        authorize! to: :show?, with: ::HangarPolicy

        models_by_manufacturer = transform_for_pie_chart(
          current_resource_owner.manufacturers.uniq
              .map do |manufacturer|
                model_ids = manufacturer.model_ids
                {manufacturer.name => authorized_scope(Vehicle.all).visible.purchased.where(loaner: false, model_id: model_ids).count}
              end
              .reduce(:merge) || []
        )

        render json: models_by_manufacturer.to_json
      end

      def models_by_classification
        authorize! to: :show?, with: ::HangarPolicy

        models_by_classification = transform_for_pie_chart(
          authorized_scope(Vehicle.all).visible.purchased.where(loaner: false)
               .joins(:model)
               .group("models.classification").count
               .map { |label, count| {(label.present? ? label.humanize : I18n.t("labels.unknown")) => count} }
               .reduce(:merge) || []
        )

        render json: models_by_classification.to_json
      end

      private

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def hangar_metrics(models, non_loaner_models, pledge_store_models, ingame_models, modules, upgrades, wishlist_models)
        lengths = models.filter_map { |m| m.length if m.length&.positive? }
        unique_model_ids = non_loaner_models.each_with_object(Set.new) { |m, set| set.add(m.id) }
        manufacturer_ids = non_loaner_models.each_with_object(Set.new) { |m, set| set.add(m.manufacturer_id) if m.manufacturer_id }
        present_classifications = non_loaner_models.each_with_object(Set.new) { |m, set| set.add(m.classification) if m.classification }
        missing_classifications = Model.classifications - present_classifications.to_a

        {
          total_money: pledge_store_models.map(&:pledge_price).sum(&:to_i) + modules.map(&:pledge_price).sum(&:to_i) + upgrades.map(&:pledge_price).sum(&:to_i),
          total_credits: ingame_models.map(&:price).sum(&:to_i),
          total_ingame_value: non_loaner_models.map(&:price).sum(&:to_i),
          total_min_crew: models.map(&:min_crew).sum(&:to_i),
          total_max_crew: models.map(&:max_crew).sum(&:to_i),
          total_cargo: models.map(&:cargo).sum(&:to_i),
          largest_ship: lengths.max,
          smallest_ship: lengths.min,
          average_pledge_price: pledge_store_models.any? ? (pledge_store_models.map(&:pledge_price).sum(&:to_i) / pledge_store_models.size) : 0,
          flight_ready_count: non_loaner_models.count { |m| m.production_status == "flight-ready" },
          unique_models_count: unique_model_ids.size,
          manufacturer_count: manufacturer_ids.size,
          missing_classifications: missing_classifications,
          wishlist_total_money: wishlist_models.map(&:pledge_price).sum(&:to_i),
          wishlist_total_credits: wishlist_models.map(&:price).sum(&:to_i)
        }
      end
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/MethodLength
    end
  end
end
