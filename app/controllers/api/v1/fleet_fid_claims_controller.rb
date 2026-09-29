# frozen_string_literal: true

module Api
  module V1
    class FleetFidClaimsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[show]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[create destroy]

      before_action :set_fleet

      def show
      end

      # Takes no FID: the only one a fleet may claim is its verified SID.
      def create
        if FleetFidClaim.open_for!(@fleet, user: current_resource_owner).nil?
          render json: ValidationError.new("fleet_fid_claim.create"), status: :bad_request
          return
        end

        render :show, status: :created
      end

      def destroy
        claim = @fleet.outgoing_fid_claims.open.first

        # A completion that lands first closes the claim, and the withdrawal
        # then stopped nothing.
        if claim.blank? || !claim.cancel!(:withdrawn)
          render json: ValidationError.new("fleet_fid_claim.destroy"), status: :bad_request
          return
        end

        render :show
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])
        authorize! @fleet, to: :manage_fid_claim?
      end
    end
  end
end
