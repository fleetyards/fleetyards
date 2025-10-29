# frozen_string_literal: true

module Api
  module V1
    class FleetVehiclesController < ::Api::BaseController
      include FleetVehicleFiltersConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index export fleetchart]

      before_action :set_fleet

      after_action -> { pagination_header(%i[vehicles models]) }, only: %i[index]

      def index
        authorize! with: FleetVehiclePolicy, context: {fleet: @fleet}

        scope = @fleet.vehicles.includes(
          :model_paint, :vehicle_upgrades, :model_upgrades, :vehicle_modules, :model_modules,
          model: [:manufacturer]
        )

        scope = scope.where(loaner: loaner_included?)

        scope = scope.where(user_id: for_members) if for_members.present?

        if price_range.present?
          vehicle_query_params["sorts"] = "model_price asc"
          scope = scope.includes(:model).where(models: {price: price_range})
        end

        if pledge_price_range.present?
          vehicle_query_params["sorts"] = "model_pledge_price asc"
          scope = scope.includes(:model).where(models: {pledge_price: pledge_price_range})
        end

        vehicle_query_params["sorts"] = sorting_params(FleetVehicle, vehicle_query_params["sorts"])

        @q = scope.ransack(vehicle_query_params)

        if ActiveModel::Type::Boolean.new.cast(params["grouped"])
          model_ids = @q.result.pluck(:model_id)

          result = @fleet.models
            .where(id: model_ids)
            .distinct
            .order(name: :asc)

          @models = result_with_pagination(result, per_page(FleetVehicle))

          render "api/v1/fleet_vehicles/models"
        else
          result = @q.result(distinct: true).includes(:model).joins(:model)

          @vehicles = result_with_pagination(result, per_page(FleetVehicle))
        end
      end

      def export
        authorize! with: FleetVehiclePolicy, context: {fleet: @fleet}

        scope = @fleet.vehicles.includes(:vehicle_upgrades, :vehicle_modules, model: [:manufacturer])

        scope = scope.where(loaner: loaner_included?)

        scope = scope.where(user_id: for_members) if for_members.present?

        vehicle_query_params["sorts"] = "model_name asc"

        @q = scope.ransack(vehicle_query_params)

        @vehicles = @q.result(distinct: true).includes(:model).joins(:model)
      end

      def fleetchart
        authorize! with: FleetVehiclePolicy, context: {fleet: @fleet}

        scope = @fleet.vehicles.includes(:model_paint, :vehicle_upgrades, :model_upgrades, :vehicle_modules, :model_modules, model: [:manufacturer])

        scope = scope.where(loaner: loaner_included?)

        @q = scope.ransack(vehicle_query_params)

        @vehicles = @q.result(distinct: true)
          .includes(:model)
          .joins(:model)
          .sort_by { |vehicle| [-vehicle.model.length, vehicle.model.name] }
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end
    end
  end
end
