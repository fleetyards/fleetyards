# frozen_string_literal: true

module Api
  module V1
    class VehiclesController < ::Api::BaseController
      include HangarFiltersConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: -> { warden.authenticate?(scope: :user) },
        only: %i[check_serial fleetchart hangar]
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" },
        unless: -> { warden.authenticate?(scope: :user) },
        except: %i[check_serial fleetchart hangar]

      before_action :set_vehicle, only: %i[show update destroy]

      def create
        @vehicle = Vehicle.new(
          vehicle_params.merge(public: true)
        )
        authorize! @vehicle

        if @vehicle.save
          render status: :created
        else
          render json: ValidationError.new("vehicle.create", errors: @vehicle.errors), status: :bad_request
        end
      end

      def create_bulk
        authorize!

        errors = []

        Vehicle.transaction do
          (vehicle_create_bulk_params[:vehicles] || []).each do |vehicle_params|
            new_vehicle = current_user.vehicles.new(vehicle_params)

            errors << new_vehicle.errors unless new_vehicle.save
          end
        end

        return if errors.blank?

        render json: ValidationError.new("vehicle.bulk_create", errors:), status: :bad_request
      end

      def show
      end

      def update
        @vehicle.vehicle_modules.destroy_all unless vehicle_params[:model_module_ids].nil?
        @vehicle.vehicle_upgrades.destroy_all unless vehicle_params[:model_upgrade_ids].nil?
        @vehicle.task_forces.destroy_all unless vehicle_params[:hangar_group_ids].nil?

        return if @vehicle.update(vehicle_params)

        render json: ValidationError.new("vehicle.update", errors: @vehicle.errors), status: :bad_request
      end

      def update_bulk
        authorize!

        errors = []

        Vehicle.transaction do
          scope = authorized_scope(Vehicle.all).where(id: params[:ids])

          scope.find_each do |vehicle|
            vehicle.task_forces.destroy_all unless vehicle_params[:hangar_group_ids].nil?

            next if vehicle.update(vehicle_bulk_params)

            errors << vehicle.errors
          end
        end

        return if errors.blank?

        render json: ValidationError.new("vehicle.bulk_update", errors:), status: :bad_request
      end

      def destroy
        return if @vehicle.destroy

        render json: ValidationError.new("vehicle.destroy", errors: @vehicle.errors), status: :bad_request
      end

      def destroy_bulk
        authorize!

        Vehicle.transaction do
          scope = authorized_scope(Vehicle.all).where(id: params[:ids])

          # rubocop:disable Rails/SkipsModelValidations
          scope.update_all(notify: false)
          # rubocop:enable Rails/SkipsModelValidations

          vehicle_ids = scope.pluck(:id)

          VehicleUpgrade.where(vehicle_id: vehicle_ids).delete_all
          VehicleModule.where(vehicle_id: vehicle_ids).delete_all
          Vehicle.where(id: vehicle_ids).delete_all
        end
      end

      def destroy_all_ingame
        authorize!

        Vehicle.transaction do
          # rubocop:disable Rails/SkipsModelValidations
          authorized_scope(Vehicle.all).purchased.where(bought_via: :ingame).update_all(notify: false)
          # rubocop:enable Rails/SkipsModelValidations

          vehicle_ids = current_user.vehicles.purchased.where(bought_via: :ingame).pluck(:id)

          VehicleUpgrade.where(vehicle_id: vehicle_ids).delete_all
          VehicleModule.where(vehicle_id: vehicle_ids).delete_all
          Vehicle.where(id: vehicle_ids).delete_all
        end
      end

      def check_serial
        authorize!

        render json: {taken: current_user.vehicles.visible.purchased.exists?(serial: params[:value]&.upcase)}
      end

      # DEPRECATED
      def fleetchart
        authorize! :show, :api_hangar

        scope = current_user.vehicles.visible.purchased

        scope = loaner_included?(scope)

        @q = scope.ransack(vehicle_query_params)

        @vehicles = @q.result(distinct: true)
          .includes(model: [:manufacturer])
          .joins(model: [:manufacturer])
          .sort_by { |vehicle| [-vehicle.model.length, vehicle.model.name] }
      end

      # DEPRECATED
      def hangar
        authorize! :index, :api_hangar
        @vehicles = current_user.vehicles.where(loaner: false).purchased.visible
      end

      private def set_vehicle
        @vehicle = current_user.vehicles.find(params[:id])

        authorize! @vehicle
      end

      private def vehicle_params
        @vehicle_params ||= params.transform_keys(&:underscore)
          .permit(
            :name, :serial, :model_id, :wanted, :name_visible, :public, :sale_notify, :flagship,
            :model_paint_id, :bought_via,
            hangar_group_ids: [], model_module_ids: [], model_upgrade_ids: [], alternative_names: []
          ).merge(user_id: current_user.id)
      end

      private def vehicle_create_bulk_params
        @vehicle_bulk_params ||= params.transform_keys(&:underscore)
          .permit(
            vehicles: [:wanted, :model_id]
          ).merge(user_id: current_user.id)
      end

      private def vehicle_bulk_params
        @vehicle_bulk_params ||= params.transform_keys(&:underscore)
          .permit(
            :wanted, :public, hangar_group_ids: []
          ).merge(user_id: current_user.id)
      end
    end
  end
end
