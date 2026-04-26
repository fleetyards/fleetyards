# frozen_string_literal: true

module Api
  module V1
    class VehicleLoadoutsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: -> { warden.authenticate?(scope: :user) },
        only: %i[index show]
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" },
        unless: -> { warden.authenticate?(scope: :user) },
        except: %i[index show]

      before_action :set_vehicle
      before_action :set_vehicle_loadout, only: %i[show update destroy activate]

      def index
        authorize! with: VehicleLoadoutPolicy

        @vehicle_loadouts = @vehicle.vehicle_loadouts
          .order(active: :desc, name: :asc)
          .includes(vehicle_loadout_hardpoints: [:model_hardpoint, :component])
      end

      def show
      end

      def create
        authorize! with: VehicleLoadoutPolicy

        @vehicle_loadout = @vehicle.vehicle_loadouts.new(vehicle_loadout_params)

        if @vehicle_loadout.save
          @vehicle_loadout.create_from_defaults! if params[:from_defaults]
          @vehicle_loadout.reload
          render status: :created
        else
          render json: ValidationError.new("vehicle_loadout.create", errors: @vehicle_loadout.errors),
            status: :bad_request
        end
      end

      def update
        return if @vehicle_loadout.update(vehicle_loadout_params)

        render json: ValidationError.new("vehicle_loadout.update", errors: @vehicle_loadout.errors),
          status: :bad_request
      end

      def destroy
        return if @vehicle_loadout.destroy

        render json: ValidationError.new("vehicle_loadout.destroy", errors: @vehicle_loadout.errors),
          status: :bad_request
      end

      def activate
        @vehicle_loadout.activate!
      end

      private def set_vehicle
        vehicle_id = params[:vehicle_id]
        @vehicle = if vehicle_id.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-/i)
          current_resource_owner.vehicles.find(vehicle_id)
        else
          current_resource_owner.vehicles.find_by!(serial: vehicle_id.upcase)
        end
      end

      private def set_vehicle_loadout
        @vehicle_loadout = @vehicle.vehicle_loadouts.find(params[:id])
        authorize! @vehicle_loadout
      end

      private def vehicle_loadout_params
        @vehicle_loadout_params ||= params.transform_keys(&:underscore)
          .permit(
            :name, :url,
            vehicle_loadout_hardpoints_attributes: [:id, :model_hardpoint_id, :component_id, :_destroy]
          )
      end
    end
  end
end
