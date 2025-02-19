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

      def members
        authorize! :show, fleet
        @q = fleet.fleet_memberships.ransack(member_query_params)

        members = @q.result

        @quick_stats = QuickStats.new(
          total: members.size,
          metrics: {
            total_admins: members.where(role: :admin).size,
            total_officers: members.where(role: :officer).size,
            total_members: members.where(role: :member).size
          }
        )
      end

      def vehicles
        authorize! :show, fleet

        scope = fleet.vehicles.includes(:model, :vehicle_upgrades, :model_upgrades, :vehicle_modules, :model_modules)

        scope = scope.where(loaner: loaner_included?)

        @q = scope.ransack(vehicle_query_params)

        @q.sorts = ["model_classification asc"]

        vehicles = @q.result
        ingame_vehicles = vehicles.select(&:bought_via_ingame?)
        models = vehicles.map(&:model)
        models_without_loaners = vehicles.reject(&:loaner?).map(&:model)
        ingame_models = ingame_vehicles.map(&:model)
        upgrades = vehicles.map(&:model_upgrades).flatten
        modules = vehicles.map(&:model_modules).flatten

        @quick_stats = QuickStats.new(
          total: vehicles.count,
          classifications: models.map(&:classification).uniq.compact.map do |classification|
            ClassificationCount.new(
              classification_count: models.count { |model| model.classification == classification },

              name: classification,
              label: classification.humanize
            )
          end,
          metrics: {
            total_money: models_without_loaners.map(&:last_pledge_price).sum(&:to_i) + modules.map(&:pledge_price).sum(&:to_i) + upgrades.map(&:pledge_price).sum(&:to_i),
            total_credits: ingame_models.map(&:price).sum(&:to_i),
            total_min_crew: models.map(&:min_crew).sum(&:to_i),
            total_max_crew: models.map(&:max_crew).sum(&:to_i),
            total_cargo: models.map(&:cargo).sum(&:to_i)
          }
        )
      end

      def model_counts
        authorize! :show, fleet

        scope = fleet.vehicles.includes(
          :model_paint, :vehicle_upgrades, :model_upgrades, :vehicle_modules, :model_modules,
          model: [:manufacturer]
        )

        scope = scope.where(loaner: loaner_included?)

        scope = scope.where(user_id: for_members) if for_members.present?

        scope = scope.includes(:model).where(models: {price: price_range}) if price_range.present?

        scope = scope.includes(:model).where(models: {last_pledge_price: pledge_price_range}) if pledge_price_range.present?

        @q = scope.ransack(vehicle_query_params)

        @model_counts = @q.result.includes(:model).joins(:model).group("models.slug").count
      end

      def vehicles_by_model
        authorize! :show, fleet

        vehicles_by_model = transform_for_bar_chart(
          fleet.vehicles.visible.where(loaner: false)
               .joins(:model)
               .group("models.name").count
        ).take(params[:limit].present? ? params[:limit].to_i : Model.count)

        render json: vehicles_by_model.to_json
      end

      def models_by_size
        authorize! :show, fleet

        models_by_size = transform_for_pie_chart(
          fleet.vehicles.visible.where(loaner: false)
               .joins(:model)
               .group("models.size").count
               .map { |label, count| {(label.present? ? label.humanize : I18n.t("labels.unknown")) => count} }
               .reduce(:merge) || []
        )

        render json: models_by_size.to_json
      end

      def models_by_production_status
        authorize! :show, fleet

        models_by_production_status = transform_for_pie_chart(
          fleet.vehicles.visible.where(loaner: false)
               .joins(:model)
               .group("models.production_status").count
               .map { |label, count| {(label.present? ? label.humanize : I18n.t("labels.unknown")) => count} }
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
                {manufacturer.name => fleet.vehicles.visible.where(loaner: false, model_id: model_ids).count}
              end
              .reduce(:merge) || []
        )

        render json: models_by_manufacturer.to_json
      end

      def models_by_classification
        authorize! :show, fleet

        models_by_classification = transform_for_pie_chart(
          fleet.vehicles.visible.where(loaner: false)
               .joins(:model)
               .group("models.classification").count
               .map { |label, count| {(label.present? ? label.humanize : I18n.t("labels.unknown")) => count} }
               .reduce(:merge) || []
        )

        render json: models_by_classification.to_json
      end

      private def fleet
        @fleet ||= current_user.fleets.where(slug: params[:fleet_slug]).first!
      end
    end
  end
end
