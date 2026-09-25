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
          scope = vehicle_scope.includes(VEHICLE_RENDER_INCLUDES)

          scope = scope.where(loaner: loaner_included?)
          scope = narrow_to_squadrons(scope)

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

            @models = result_with_pagination(result, per_page(Model))

            render "api/v1/public/fleet_vehicles/models"
          else
            result = Vehicle.where(
              Vehicle.arel_table[:id].in(@q.result(distinct: true).reorder(nil).select(:id).arel)
            )
              .order(@q.result.order_values)
              .includes(VEHICLE_RENDER_INCLUDES)
              .joins(model: :manufacturer)

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
            .joins(model: :manufacturer)
            .all
        end

        # See the fleet's own list for why an empty list is not the same as no
        # filter at all.
        #
        # This list names every ship's owner, so narrowed to a squadron it is
        # that squadron's roster -- and a roster is only for a reader the fleet
        # shows its members to. The stats take the same filter freely: a count
        # names nobody.
        private def narrow_to_squadrons(scope)
          if vehicle_query_params["squadron_slug_in"].present?
            authorize! @fleet, to: :show_members?, with: ::Public::FleetPolicy
          end

          user_ids = for_squadrons(@fleet)

          return scope if user_ids.nil?

          scope.where(user_id: user_ids)
        end

        # The ships the list starts from. `embed` is the fleet's own surface and
        # keeps the whole fleet deliberately.
        private def vehicle_scope
          @fleet.vehicles
        end

        private def set_fleet
          @fleet = Fleet.kept.find_by!(slug: params[:fleet_slug])

          authorize! @fleet, to: :show?, with: ::Public::FleetPolicy
        end
      end
    end
  end
end
