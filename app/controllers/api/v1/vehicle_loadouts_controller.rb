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

        @vehicle_loadouts = @vehicle.vehicle_loadouts.includes(:items).order(active: :desc, name: :asc)
      end

      def show
      end

      def create
        authorize! with: VehicleLoadoutPolicy

        @vehicle_loadout = @vehicle.vehicle_loadouts.new(vehicle_loadout_params)

        if @vehicle_loadout.save
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
        @vehicle = current_resource_owner.vehicles.find_by_id_or_serial!(params[:vehicle_id])
      end

      private def set_vehicle_loadout
        @vehicle_loadout = @vehicle.vehicle_loadouts.find(params[:id])
        authorize! @vehicle_loadout
      end

      private def vehicle_loadout_params
        @vehicle_loadout_params ||= begin
          # The kind is chosen once: a link turned fleetyards loadout, or the
          # other way round, would keep fields the new kind does not allow.
          keys = [:name, :url, {items: [:slot_path, :item_type, :item_id]}]
          keys << :kind if action_name == "create"
          permitted = params.transform_keys(&:underscore).permit(*keys)

          permitted[:item_list] = permitted.delete(:items) if permitted.key?(:items)
          permitted
        end
      end
    end
  end
end
