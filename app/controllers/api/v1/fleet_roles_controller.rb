# frozen_string_literal: true

module Api
  module V1
    class FleetRolesController < ::Api::BaseController
      rescue_from ActiveRecord::RecordNotFound do |_exception|
        not_found(I18n.t("messages.record_not_found.fleet", slug: params[:fleet_slug]))
      end

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[update]

      before_action :set_fleet, only: %i[index update]

      def index
        authorize! @fleet, to: :show?, with: FleetPolicy

        @fleet_roles = @fleet.fleet_roles.ranked
      end

      def update
        authorize! @fleet, to: :show?, with: FleetPolicy
        @fleet_role = @fleet.fleet_roles.find(params[:id])

        authorize! @fleet_role, with: FleetRolePolicy, context: {fleet: @fleet}

        if @fleet_role.update(fleet_role_params)
          render :show
        else
          render json: ValidationError.new("fleet_roles.update", errors: @fleet_role.errors), status: :bad_request
        end
      end

      private def fleet_role_params
        params.permit(:name)
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])
      end
    end
  end
end
