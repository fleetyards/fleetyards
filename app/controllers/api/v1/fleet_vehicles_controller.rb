# frozen_string_literal: true

module Api
  module V1
    class FleetVehiclesController < ::Api::BaseController
      include FleetVehicleFiltersConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index export export_hangar_link fleetchart]

      before_action :set_fleet

      after_action -> { pagination_header(%i[vehicles models]) }, only: %i[index]

      VEHICLE_RENDER_INCLUDES = [
        :model_paint,
        :module_package,
        :vehicle_loadouts,
        {user: [:omniauth_connections]},
        {model: [:manufacturer]},
        {vehicle_modules: :model_module},
        {vehicle_upgrades: :model_upgrade},
        {task_forces: :hangar_group}
      ].freeze

      def index
        authorize! with: FleetVehiclePolicy, context: {fleet: @fleet}

        scope = vehicle_scope.includes(VEHICLE_RENDER_INCLUDES)

        scope = scope.where(loaner: loaner_included?)

        scope = scope.where(user_id: for_members) if for_members.present?
        scope = narrow_to_squadrons(scope)

        if price_range.present?
          vehicle_query_params["sorts"] = "model_price asc"
          scope = scope.includes(:model).where(models: {price: price_range})
        end

        if pledge_price_range.present?
          vehicle_query_params["sorts"] = "model_pledge_price asc"
          scope = scope.includes(:model).where(models: {pledge_price: pledge_price_range})
        end

        normalize_sort_params(vehicle_query_params)
        vehicle_query_params["sorts"] = sorting_params(FleetVehicle, vehicle_query_params["sorts"])

        @q = scope.ransack(vehicle_query_params)

        if ActiveModel::Type::Boolean.new.cast(params["grouped"])
          model_ids = @q.result.pluck(:model_id)

          # Plucked from the fleet's own vehicles, so the ids are already scoped, and
          # a plain lookup needs no DISTINCT that would forbid ordering by a join.
          result = Model.where(id: model_ids)
            .ransack(sorts: FleetVehicle.model_sorts(vehicle_query_params["sorts"]))
            .result

          @models = result_with_pagination(result, per_page(FleetVehicle))

          render "api/v1/fleet_vehicles/models"
        else
          result = Vehicle.where(
            Vehicle.arel_table[:id].in(@q.result(distinct: true).reorder(nil).select(:id).arel)
          )
            .order(@q.result.order_values)
            .includes(VEHICLE_RENDER_INCLUDES).joins(model: :manufacturer)

          @vehicles = result_with_pagination(result, per_page(FleetVehicle))
        end
      end

      def export
        authorize! with: FleetVehiclePolicy, context: {fleet: @fleet}

        @vehicles = export_vehicles
      end

      def export_hangar_link
        authorize! with: FleetVehiclePolicy, context: {fleet: @fleet}

        @vehicles = export_vehicles
      end

      def fleetchart
        authorize! with: FleetVehiclePolicy, context: {fleet: @fleet}

        scope = vehicle_scope.includes(VEHICLE_RENDER_INCLUDES)

        scope = scope.where(loaner: loaner_included?)
        scope = narrow_to_squadrons(scope)

        @q = scope.ransack(vehicle_query_params)
        @vehicles = Vehicle.where(
          Vehicle.arel_table[:id].in(@q.result(distinct: true).reorder(nil).select(:id).arel)
        )
          .includes(VEHICLE_RENDER_INCLUDES)
          .joins(:model)
          .sort_by { |vehicle| [-vehicle.model.length, vehicle.model.name] }
      end

      private def export_vehicles
        scope = vehicle_scope

        scope = scope.where(loaner: loaner_included?)

        scope = scope.where(user_id: for_members) if for_members.present?
        scope = narrow_to_squadrons(scope)

        vehicle_query_params["sorts"] = "model_name asc"

        @q = scope.ransack(vehicle_query_params)

        Vehicle.where(
          Vehicle.arel_table[:id].in(@q.result(distinct: true).reorder(nil).select(:id).arel)
        )
          .order(@q.result.order_values)
          .includes(
            :model_paint,
            :model_modules,
            :model_upgrades,
            :hangar_groups,
            {model: :manufacturer},
            {user: {avatar_attachment: :blob}}
          )
          .joins(:model)
      end

      # `nil` means no squadron was named and the scope is left alone; an empty
      # list means the named squadrons hold nobody, which has to answer "no
      # ships" rather than widening back to the whole fleet.
      private def narrow_to_squadrons(scope)
        user_ids = for_squadrons(@fleet)

        return scope if user_ids.nil?

        scope.where(user_id: user_ids)
      end

      # The ships every action here starts from. A seam rather than
      # `@fleet.vehicles` inline, so a subclass scoped to part of the fleet --
      # `FleetSquadronVehiclesController` -- narrows all of them at once.
      private def vehicle_scope
        @fleet.vehicles
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end
    end
  end
end
