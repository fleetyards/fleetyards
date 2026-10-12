# frozen_string_literal: true

module Api
  module V1
    class VehicleLogEntriesController < ::Api::BaseController
      include VehicleOverviewFeatureConcern

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "hangar", "hangar:read" },
        unless: -> { warden.authenticate?(scope: :user) },
        only: %i[index]
      before_action -> { doorkeeper_authorize! "hangar", "hangar:write" },
        unless: -> { warden.authenticate?(scope: :user) },
        except: %i[index]
      before_action :check_vehicle_overview_feature

      before_action :set_vehicle
      before_action :set_log_entry, only: %i[update destroy]

      def index
        authorize! with: VehicleLogEntryPolicy

        @log_entries = @vehicle.log_entries.chronological
      end

      def create
        authorize! with: VehicleLogEntryPolicy

        @log_entry = @vehicle.log_entries.new(public: @vehicle.log_entries_public_by_default)
        @log_entry.assign_attributes(log_entry_params)

        if @log_entry.save
          render status: :created
        else
          render json: ValidationError.new("vehicle_log_entry.create", errors: @log_entry.errors),
            status: :bad_request
        end
      end

      def update
        return if @log_entry.update(log_entry_params)

        render json: ValidationError.new("vehicle_log_entry.update", errors: @log_entry.errors),
          status: :bad_request
      end

      def destroy
        return if @log_entry.destroy

        render json: ValidationError.new("vehicle_log_entry.destroy", errors: @log_entry.errors),
          status: :bad_request
      end

      private def set_vehicle
        vehicle_id = params[:vehicle_id]
        @vehicle = if vehicle_id.match?(/\A[0-9a-f]{8}-[0-9a-f]{4}-/i)
          current_resource_owner.vehicles.find(vehicle_id)
        else
          current_resource_owner.vehicles.find_by!(serial: vehicle_id.upcase)
        end
      end

      private def set_log_entry
        @log_entry = @vehicle.log_entries.find(params[:id])
        authorize! @log_entry
      end

      private def log_entry_params
        @log_entry_params ||= params.transform_keys(&:underscore)
          .permit(:title, :body, :logged_at, :public)
      end
    end
  end
end
