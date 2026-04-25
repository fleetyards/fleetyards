# frozen_string_literal: true

module Api
  module V1
    class FleetStatsController < ::Api::BaseController
      include FleetVehicleFiltersConcern
      include FleetMemberFiltersConcern
      include ChartHelper

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?
      before_action :set_fleet

      def members
        @q = @fleet.fleet_memberships.accepted.ransack(member_query_params)

        members = @q.result

        members_by_role = members.joins(:fleet_role).group("fleet_roles.name").count

        @quick_stats = QuickStats.new(
          total: members.size,
          metrics: {
            members_by_role:
          }
        )
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def vehicles
        scope = @fleet.vehicles.includes(:model, :vehicle_upgrades, :model_upgrades, :vehicle_modules, :model_modules)

        scope = scope.where(loaner: loaner_included?)

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

        @quick_stats = QuickStats.new(
          total: vehicles.count,
          classifications: models.map(&:classification).uniq.compact.map do |classification|
            ClassificationCount.new(
              classification_count: models.count { |model| model.classification == classification },

              name: classification,
              label: classification.humanize
            )
          end,
          metrics: fleet_metrics(models, non_loaner_models, pledge_store_models, ingame_models, modules, upgrades)
        )
      end
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/CyclomaticComplexity

      def model_counts
        scope = @fleet.vehicles.includes(
          :model_paint, :vehicle_upgrades, :model_upgrades, :vehicle_modules, :model_modules,
          model: [:manufacturer]
        )

        scope = scope.where(loaner: loaner_included?)

        scope = scope.where(user_id: for_members) if for_members.present?

        scope = scope.includes(:model).where(models: {price: price_range}) if price_range.present?

        scope = scope.includes(:model).where(models: {pledge_price: pledge_price_range}) if pledge_price_range.present?

        count_params = vehicle_query_params.except("sorts", "s")
        @q = scope.ransack(count_params)

        @model_counts = @q.result.includes(:model).joins(:model).group("models.slug").count
      end

      def vehicles_by_model
        vehicles_by_model = transform_for_bar_chart(
          @fleet.vehicles.visible.where(loaner: false)
               .joins(:model)
               .group("models.name").count
        ).take(params[:limit].present? ? params[:limit].to_i : 10)

        render json: vehicles_by_model.to_json
      end

      def models_by_size
        models_by_size = transform_for_pie_chart(
          @fleet.vehicles.visible.where(loaner: false)
               .joins(:model)
               .group("models.size").count
               .map { |label, count| {(label.present? ? label.humanize : I18n.t("labels.unknown")) => count} }
               .reduce(:merge) || []
        )

        render json: models_by_size.to_json
      end

      def models_by_production_status
        models_by_production_status = transform_for_pie_chart(
          @fleet.vehicles.visible.where(loaner: false)
               .joins(:model)
               .group("models.production_status").count
               .map { |label, count| {(label.present? ? label.humanize : I18n.t("labels.unknown")) => count} }
               .reduce(:merge) || []
        )

        render json: models_by_production_status.to_json
      end

      def models_by_manufacturer
        models_by_manufacturer = transform_for_pie_chart(
          @fleet.manufacturers.uniq
              .map do |manufacturer|
                model_ids = manufacturer.model_ids
                {manufacturer.name => @fleet.vehicles.visible.where(loaner: false, model_id: model_ids).count}
              end
              .reduce(:merge) || []
        )

        render json: models_by_manufacturer.to_json
      end

      def models_by_classification
        models_by_classification = transform_for_pie_chart(
          @fleet.vehicles.visible.where(loaner: false)
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
      def fleet_metrics(models, non_loaner_models, pledge_store_models, ingame_models, modules, upgrades)
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
          largest_ship: lengths.max&.to_f,
          smallest_ship: lengths.min&.to_f,
          average_pledge_price: pledge_store_models.any? ? (pledge_store_models.map(&:pledge_price).sum(&:to_i) / pledge_store_models.size) : 0,
          flight_ready_count: non_loaner_models.count { |m| m.production_status == "flight-ready" },
          unique_models_count: unique_model_ids.size,
          manufacturer_count: manufacturer_ids.size,
          missing_classifications: missing_classifications,
          wishlist_total_money: 0,
          wishlist_total_credits: 0
        }
      end
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/MethodLength

      def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end
    end
  end
end
