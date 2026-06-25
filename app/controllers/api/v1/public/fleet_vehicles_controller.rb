# frozen_string_literal: true

module Api
  module V1
    module Public
      class FleetVehiclesController < ::Api::PublicBaseController
        include FleetVehicleFiltersConcern

        before_action :set_fleet
        after_action -> { pagination_header(%i[vehicles models]) }, only: %i[index]

        VEHICLE_RENDER_INCLUDES = [
          :model_paint,
          :module_package,
          :vehicle_loadouts,
          :public_hangar_groups,
          {model: [:manufacturer]},
          {vehicle_modules: :model_module},
          {vehicle_upgrades: :model_upgrade},
          {user: {avatar_attachment: :blob}}
        ].freeze

        rescue_from ActiveRecord::RecordNotFound, ActionPolicy::Unauthorized do |_exception|
          not_found(I18n.t("messages.record_not_found.fleet", slug: params[:fleet_slug]))
        end

        def index
          scope = @fleet.vehicles.includes(VEHICLE_RENDER_INCLUDES)

          scope = scope.where(loaner: loaner_included?)

          normalize_sort_params(vehicle_query_params)
          vehicle_query_params["sorts"] = sorting_params(FleetVehicle, vehicle_query_params["sorts"])

          @q = scope.ransack(vehicle_query_params)

          if ActiveModel::Type::Boolean.new.cast(params["grouped"])
            model_ids = @q.result.pluck(:model_id)

            result = @fleet.models
              .where(id: model_ids)
              .distinct
              .order(@q.result.order_values.presence || "name ASC")

            @models = result_with_pagination(result, per_page(Model))

            render "api/v1/public/fleet_vehicles/models"
          else
            result = Vehicle.where(
              Vehicle.arel_table[:id].in(@q.result(distinct: true).reorder(nil).select(:id).arel)
            )
              .order(@q.result.order_values)
              .includes(VEHICLE_RENDER_INCLUDES)
              .joins(:model)

            @vehicles = result_with_pagination(result, per_page(Vehicle))
          end
        end

        def embed
          if !(request.referrer || "").include?(FRONTEND_DOMAIN) && !request.referrer.blank?
            ahoy.track "fleet_embedding", request.path_parameters
          end

          scope = @fleet.vehicles.includes(VEHICLE_RENDER_INCLUDES)

          scope = scope.where(loaner: loaner_included?)

          normalize_sort_params(vehicle_query_params)
          vehicle_query_params["sorts"] = sorting_params(FleetVehicle, vehicle_query_params["sorts"])

          @q = scope.ransack(vehicle_query_params)
          @vehicles = Vehicle.where(
            Vehicle.arel_table[:id].in(@q.result(distinct: true).reorder(nil).select(:id).arel)
          )
            .order(@q.result.order_values)
            .includes(VEHICLE_RENDER_INCLUDES)
            .joins(:model)
            .all
        end

        def fleetchart
          scope = @fleet.vehicles.includes(VEHICLE_RENDER_INCLUDES)

          scope = scope.where(loaner: loaner_included?)

          @q = scope.ransack(vehicle_query_params)
          @vehicles = Vehicle.where(
            Vehicle.arel_table[:id].in(@q.result(distinct: true).reorder(nil).select(:id).arel)
          )
            .includes(VEHICLE_RENDER_INCLUDES)
            .joins(:model)
            .sort_by { |vehicle| [-vehicle.model.length, vehicle.model.name] }
        end

        private def set_fleet
          @fleet = Fleet.kept.find_by!(slug: params[:fleet_slug])

          authorize! @fleet, to: :show?, with: ::Public::FleetPolicy
        end
      end
    end
  end
end
