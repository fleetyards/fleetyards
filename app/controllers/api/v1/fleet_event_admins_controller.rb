# frozen_string_literal: true

module Api
  module V1
    class FleetEventAdminsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[create destroy]

      before_action :check_mission_builder_feature
      before_action :set_fleet
      before_action :set_event
      before_action :set_admin, only: %i[destroy]

      def index
        authorize! @event, with: FleetEventAdminPolicy

        @admins = @event.fleet_event_admins.includes(:user, :granted_by)
      end

      def create
        authorize! @event, with: FleetEventAdminPolicy, to: :create?

        target_user = User.find_by!(id: params[:user_id])
        @admin = @event.fleet_event_admins.new(
          user: target_user,
          role: params[:role].presence || "admin",
          granted_by: current_resource_owner
        )

        if @admin.save
          render :show, status: :created
        else
          render json: ValidationError.new("fleet_event_admins.create", errors: @admin.errors), status: :bad_request
        end
      end

      def destroy
        authorize! @admin, with: FleetEventAdminPolicy, context: {fleet_event: @event}

        @admin.destroy
        head :no_content
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])
      end

      private def set_event
        @event = @fleet.fleet_events.find_by!(slug: params[:fleet_event_slug])
      end

      private def set_admin
        @admin = @event.fleet_event_admins.find(params[:id])
      end

      private def check_mission_builder_feature
        return if feature_enabled?("mission_builder")

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
