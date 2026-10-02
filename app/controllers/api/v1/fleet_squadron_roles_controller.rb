# frozen_string_literal: true

module Api
  module V1
    class FleetSquadronRolesController < ::Api::BaseController
      include FleetSquadronScoped

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[update]

      before_action :set_fleet
      before_action :check_fleet_squadrons_feature

      def index
        authorize! with: FleetSquadronRolePolicy, context: {fleet: @fleet}

        FleetSquadronRole.default_for(@fleet)
        @fleet_squadron_roles = @fleet.fleet_squadron_roles
      end

      def update
        authorize! with: FleetSquadronRolePolicy, context: {fleet: @fleet}

        @fleet_squadron_role = @fleet.fleet_squadron_roles.find(params[:id])

        saved = FleetSquadronRole.transaction do
          @fleet_squadron_role.update(fleet_squadron_role_params) &&
            (!make_default? || make_default!)
        end

        if saved
          render :show
        else
          render json: ValidationError.new("fleet_squadron_roles.update", errors: @fleet_squadron_role.errors), status: :bad_request
        end
      end

      private def make_default?
        ActiveModel::Type::Boolean.new.cast(params[:defaultRank] || params[:default_rank])
      end

      private def make_default!
        @fleet_squadron_role.make_default!
        true
      rescue ActiveRecord::RecordInvalid
        raise ActiveRecord::Rollback
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end

      private def fleet_squadron_role_params
        params.permit(:name)
      end
    end
  end
end
