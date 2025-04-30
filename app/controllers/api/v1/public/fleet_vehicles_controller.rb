# frozen_string_literal: true

module Api
  module V1
    module Public
      class FleetVehiclesController < ::Api::PublicBaseController
        include FleetVehicleFiltersConcern

        before_action :set_fleet
        after_action -> { pagination_header(%i[vehicles models]) }, only: %i[index]

        def index
          scope = @fleet.vehicles.includes(:model_paint, :vehicle_upgrades, :model_upgrades, :vehicle_modules, :model_modules, model: [:manufacturer])

          scope = scope.where(loaner: loaner_included?)

          vehicle_query_params["sorts"] = sorting_params(FleetVehicle)

          @q = scope.ransack(vehicle_query_params)

          if ActiveModel::Type::Boolean.new.cast(params["grouped"])
            model_ids = @q.result.pluck(:model_id)

            result = @fleet.models
              .where(id: model_ids)
              .distinct
              .order(name: :asc)

            @models = result_with_pagination(result, per_page(Model))

            render "api/v1/public/fleet_vehicles/models"
          else
            result = @q.result(distinct: true)
              .includes(:model)
              .joins(:model)

            @vehicles = result_with_pagination(result, per_page(Vehicle))
          end
        end

        def embed
          if !(request.referrer || "").include?(FRONTEND_DOMAIN) && !request.referrer.blank?
            ahoy.track "fleet_embedding", request.path_parameters
          end

          scope = @fleet.vehicles.includes(:model_paint, :vehicle_upgrades, :model_upgrades, :vehicle_modules, :model_modules, model: [:manufacturer])

          vehicle_query_params["sorts"] = sorting_params(FleetVehicle)

          @q = scope.ransack(vehicle_query_params)

          @vehicles = @q.result(distinct: true)
            .includes(:model)
            .joins(:model)
            .all
        end

        def fleetchart
          scope = @fleet.vehicles.includes(:model_paint, :vehicle_upgrades, :model_upgrades, :vehicle_modules, :model_modules, model: [:manufacturer])

          scope = scope.where(loaner: loaner_included?)

          @q = scope.ransack(vehicle_query_params)

          @vehicles = @q.result(distinct: true)
            .includes(:model)
            .joins(:model)
            .sort_by { |vehicle| [-vehicle.model.length, vehicle.model.name] }
        end

        private def set_fleet
          @fleet = Fleet.find_by!(slug: params[:fleet_slug])

          authorize! @fleet, to: :show?, with: ::Public::FleetPolicy
        end
      end
    end
  end
end
