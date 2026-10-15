# frozen_string_literal: true

module Api
  module V1
    class VehiclesController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: -> { warden.authenticate?(scope: :user) },
        only: %i[check_serial]
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" },
        unless: -> { warden.authenticate?(scope: :user) },
        except: %i[check_serial]

      before_action :set_vehicle, only: %i[show update destroy move]
      before_action :require_supporter_for_plaque_style, only: %i[create update]

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
            new_vehicle = current_resource_owner.vehicles.new(vehicle_params)

            errors << new_vehicle.errors unless new_vehicle.save
          end
        end

        return if errors.blank?

        render json: ValidationError.new("vehicle.bulk_create", errors:), status: :bad_request
      end

      def show
        @fleets = current_resource_owner.fleets
          .where(id: @vehicle.fleet_vehicles.select(:fleet_id))
          .with_attached_logo
          .order(:name)
      end

      def update
        # Owned paints are written as soon as they are assigned, so a paint the
        # ship cannot own raises from inside `update` rather than failing it.
        updated = ActiveRecord::Base.transaction do
          @vehicle.vehicle_modules.destroy_all unless vehicle_params[:model_module_ids].nil?
          @vehicle.vehicle_upgrades.destroy_all unless vehicle_params[:model_upgrade_ids].nil?
          @vehicle.task_forces.destroy_all unless vehicle_params[:hangar_group_ids].nil?

          @vehicle.update(writable_params(@vehicle, vehicle_params)) || raise(ActiveRecord::Rollback)
        end
        return if updated

        render json: ValidationError.new("vehicle.update", errors: @vehicle.errors), status: :bad_request
      rescue ActiveRecord::RecordInvalid => e
        render json: ValidationError.new("vehicle.update", errors: e.record.errors), status: :bad_request
      end

      def move
        after_id = vehicle_move_params[:after_id]
        before_id = vehicle_move_params[:before_id]

        if after_id.blank? == before_id.blank? || [after_id, before_id].include?(@vehicle.id)
          render json: ValidationError.new("vehicle.move"), status: :bad_request
          return
        end

        neighbour = current_resource_owner.vehicles.find(after_id || before_id)

        @vehicle.move_next_to!(neighbour, after: after_id.present?)

        head :no_content
      end

      def update_bulk
        authorize!

        errors = []

        Vehicle.transaction do
          scope = authorized_scope(Vehicle.all).where(id: params[:ids])

          scope.find_each do |vehicle|
            vehicle.task_forces.destroy_all unless vehicle_params[:hangar_group_ids].nil?

            next if vehicle.update(writable_params(vehicle, vehicle_bulk_params))

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

          scope.update_all(notify: false)

          vehicle_ids = scope.pluck(:id)

          Vehicle.delete_with_dependents(vehicle_ids)
        end
      end

      def destroy_all_ingame
        authorize!

        Vehicle.transaction do
          authorized_scope(Vehicle.all).purchased.where(bought_via: :ingame).update_all(notify: false)

          vehicle_ids = current_resource_owner.vehicles.purchased.where(bought_via: :ingame).pluck(:id)

          Vehicle.delete_with_dependents(vehicle_ids)
        end
      end

      def check_serial
        authorize!

        render json: {taken: current_resource_owner.vehicles.where(hidden: false).purchased.exists?(serial: Vehicle.normalized_serial(params[:value]))}
      end

      private def set_vehicle
        @vehicle = find_vehicle(params[:id])

        authorize! @vehicle
      end

      private def find_vehicle(identifier)
        current_resource_owner.vehicles.find_by_id_or_serial!(identifier)
      end

      private def vehicle_params
        @vehicle_params ||= params.transform_keys(&:underscore)
          .permit(
            :name, :serial, :model_id, :wanted, :name_visible, :public, :sale_notify, :flagship,
            :bought_via, :hidden_by_user, *vehicle_overview_params,
            hangar_group_ids: [], model_module_ids: [], model_upgrade_ids: [], model_paint_ids: [], alternative_names: []
          ).merge(user_id: current_resource_owner.id)
      end

      # Anyone can put a plaque on a ship, in the default style; the other
      # styles are a supporter perk. A style picked earlier stays where it is.
      private def require_supporter_for_plaque_style
        style = vehicle_params[:plaque_style]
        return if style.blank? || style == ::Vehicle::DEFAULT_PLAQUE_STYLE
        return if style == @vehicle&.plaque_style
        return if current_resource_owner.supporter?

        render json: {
          code: "supporter_required",
          message: I18n.t("messages.supporter_required")
        }, status: :forbidden
      end

      private def vehicle_overview_params
        return [] unless feature_enabled?("vehicle_overview")

        %i[
          image picture_type picture_id log_entries_public_by_default location location_id
          dedication launched_on launch_port launch_port_location_id affiliation operations_group plaque_captain plaque_style plaque_image
        ]
      end

      private def vehicle_move_params
        params.transform_keys(&:underscore).permit(:after_id, :before_id)
      end

      private def vehicle_create_bulk_params
        @vehicle_bulk_params ||= params.transform_keys(&:underscore)
          .permit(
            vehicles: [:wanted, :model_id]
          ).merge(user_id: current_resource_owner.id)
      end

      private def vehicle_bulk_params
        @vehicle_bulk_params ||= params.transform_keys(&:underscore)
          .permit(
            :wanted, :public, :hidden_by_user, hangar_group_ids: []
          ).merge(user_id: current_resource_owner.id)
      end

      # A loaner or bundled snub craft takes `hidden_by_user` from its parent,
      # whose next save would overwrite a value written here.
      private def writable_params(vehicle, attributes)
        return attributes unless vehicle.loaner? || vehicle.bundled?

        attributes.except(:hidden_by_user)
      end
    end
  end
end
