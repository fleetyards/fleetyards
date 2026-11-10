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
        :module_package,
        *Vehicle::LOADOUT_PRELOADS,
        {user: [:omniauth_connections]},
        {model: [:manufacturer]},
        {vehicle_modules: :model_module},
        {vehicle_upgrades: :model_upgrade},
        {task_forces: :hangar_group},
        {image_attachment: :blob},
        :launch_port_location
      ].freeze

      def index
        authorize! with: FleetVehiclePolicy, context: {fleet: @fleet}

        @q, sorts = filtered_vehicles(
          vehicle_scope.includes(VEHICLE_RENDER_INCLUDES).preload(Vehicle::PICTURE_PRELOADS)
        )

        if ActiveModel::Type::Boolean.new.cast(params["grouped"])
          @models = result_with_pagination(grouped_models(@q, sorts), per_page(FleetVehicle))

          render "api/v1/fleet_vehicles/models"
        else
          result = Vehicle.where(
            Vehicle.arel_table[:id].in(@q.result(distinct: true).reorder(nil).select(:id).arel)
          )
            .order(@q.result.order_values)
            .includes(VEHICLE_RENDER_INCLUDES).preload(Vehicle::PICTURE_PRELOADS).joins(model: :manufacturer)

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

      # Every ship the filters admit, unpaginated and stripped to what a chart
      # draws from. A full vehicle carries its whole model, which for a fleet of
      # thousands is hundreds of megabytes; here each model is sent once.
      def fleetchart
        authorize! with: FleetVehiclePolicy, context: {fleet: @fleet}

        @q, _sorts = filtered_vehicles(vehicle_scope)

        @vehicles = Vehicle.where(
          Vehicle.arel_table[:id].in(@q.result(distinct: true).reorder(nil).select(:id).arel)
        )
          .order(@q.result.order_values)
          .joins(model: :manufacturer)
          .includes(:user)
          .to_a

        @models = Model.where(id: @vehicles.map(&:model_id).uniq).includes(:manufacturer)
        @module_packages = ModelModulePackage
          .where(id: @vehicles.filter_map(&:module_package_id).uniq)
          .includes(:model_modules)
        @squadrons_by_user = squadrons_by_user
      end

      # The list and its chart show the same ships, so both filter through here.
      # Returns the search and the sorts it was given.
      private def filtered_vehicles(scope)
        scope = scope.where(loaner: loaner_included?)
        scope = scope.where(user_id: for_members) if for_members.present?
        scope = narrow_to_squadrons(scope)

        normalize_sort_params(vehicle_query_params)
        sorts = sorting_params(FleetVehicle, vehicle_query_params["sorts"])
        vehicle_query_params["sorts"] = FleetVehicle.vehicle_sorts(sorts)

        [scope.ransack(vehicle_query_params), sorts]
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
            :model_paints,
            :model_modules,
            :model_upgrades,
            :hangar_groups,
            {model: :manufacturer},
            {user: {avatar_attachment: :blob}}
          )
          .joins(:model)
      end

      # The ordinary squadron each member flies in. Teams are left out: a member
      # holds at most one ordinary squadron, but any number of teams, and a ship
      # is grouped under one heading.
      private def squadrons_by_user
        return {} unless @fleet.squadrons_enabled
        return {} unless allowed_to?(:index?, with: FleetSquadronPolicy, context: {fleet: @fleet})

        FleetSquadron
          .joins(fleet_squadron_memberships: :fleet_membership)
          .merge(FleetMembership.kept.accepted)
          .where(fleet_id: @fleet.id, team: false)
          .select("fleet_squadrons.*", "fleet_memberships.user_id AS member_user_id")
          .index_by(&:member_user_id)
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
