# frozen_string_literal: true

module Api
  module V1
    class VehiclesController < ::Api::BaseController
      include HangarFiltersConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: :user_signed_in?,
        only: %i[show check_serial fleetchart public_fleetchart hangar]
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" },
        unless: :user_signed_in?,
        except: %i[show check_serial fleetchart public_fleetchart hangar]

      skip_authorization_check only: [:public_fleetchart]

      def show
        authorize! :read, vehicle
      end

      def create
        @vehicle = Vehicle.new(
          vehicle_params.merge(public: true)
        )
        authorize! :create, vehicle

        if vehicle.save
          render status: :created
        else
          render json: ValidationError.new("vehicle.create", errors: @vehicle.errors), status: :bad_request
        end
      end

      def update
        authorize! :update, vehicle

        vehicle.vehicle_modules.destroy_all unless vehicle_params[:model_module_ids].nil?
        vehicle.vehicle_upgrades.destroy_all unless vehicle_params[:model_upgrade_ids].nil?
        vehicle.task_forces.destroy_all unless vehicle_params[:hangar_group_ids].nil?

        return if vehicle.update(vehicle_params)

        render json: ValidationError.new("vehicle.update", errors: @vehicle.errors), status: :bad_request
      end

      def update_bulk
        authorize! :update_bulk, :api_hangar

        errors = []

        Vehicle.transaction do
          scope = current_user.vehicles.where(id: params[:ids])

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
        authorize! :destroy, vehicle

        return if vehicle.destroy

        render json: ValidationError.new("vehicle.destroy", errors: @vehicle.errors), status: :bad_request
      end

      def destroy_bulk
        authorize! :destroy_bulk, :api_hangar

        Vehicle.transaction do
          scope = current_user.vehicles.where(id: params[:ids])

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
        authorize! :destroy_all, :api_hangar

        Vehicle.transaction do
          # rubocop:disable Rails/SkipsModelValidations
          current_user.vehicles.purchased.where(bought_via: :ingame).update_all(notify: false)
          # rubocop:enable Rails/SkipsModelValidations

          vehicle_ids = current_user.vehicles.purchased.where(bought_via: :ingame).pluck(:id)

          VehicleUpgrade.where(vehicle_id: vehicle_ids).delete_all
          VehicleModule.where(vehicle_id: vehicle_ids).delete_all
          Vehicle.where(id: vehicle_ids).delete_all
        end
      end

      def check_serial
        authorize! :check_serial, :api_vehicles

        render json: {serialTaken: current_user.vehicles.visible.purchased.exists?(serial: vehicle_params[:serial]&.upcase)}
      end

      def bought_via_filters
        authorize! :index, :api_hangar

        @filters = Vehicle.bought_via_filters

        render "api/v1/shared/filters"
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

      private def vehicle
        @vehicle ||= Vehicle.find(params[:id])
      end
      helper_method :vehicle

      private def vehicle_params
        @vehicle_params ||= params.transform_keys(&:underscore)
          .permit(
            :name, :serial, :model_id, :wanted, :name_visible, :public, :sale_notify, :flagship,
            :model_paint_id, :bought_via,
            hangar_group_ids: [], model_module_ids: [], model_upgrade_ids: [], alternative_names: []
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
