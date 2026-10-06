# frozen_string_literal: true

module Api
  module V1
    # Members asking to be posted to a squadron. Teams take no requests -- they
    # are joined directly -- so these are only ever for an ordinary squadron.
    class FleetSquadronRequestsController < ::Api::BaseController
      include FleetSquadronScoped

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read" },
        unless: :user_signed_in?,
        only: %i[index]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write" },
        unless: :user_signed_in?,
        only: %i[create accept destroy]

      before_action :set_fleet
      before_action :check_fleet_squadrons_feature
      before_action :set_fleet_squadron

      def index
        authorize! with: FleetSquadronRequestPolicy, context: {fleet: @fleet, fleet_squadron: @fleet_squadron}

        @fleet_squadron_requests = @fleet_squadron.fleet_squadron_requests
          .pending
          .includes(fleet_membership: FleetMembership::ROSTER_PRELOADS)
          .order(created_at: :asc)
      end

      def create
        @fleet_squadron_request = @fleet_squadron.fleet_squadron_requests.new(fleet_membership: viewer_membership)

        authorize! @fleet_squadron_request, context: {fleet: @fleet}

        if @fleet_squadron_request.save
          render :show, status: :created
        else
          render json: ValidationError.new("fleet_squadron_requests.create", errors: @fleet_squadron_request.errors), status: :bad_request
        end
      end

      def accept
        authorize! with: FleetSquadronRequestPolicy, to: :index?, context: {fleet: @fleet, fleet_squadron: @fleet_squadron}

        request = find_request!

        authorize! request, context: {fleet: @fleet}

        request.accept!

        head :no_content
      rescue ActiveRecord::RecordInvalid => e
        render json: ValidationError.new("fleet_squadron_requests.accept", errors: e.record.errors), status: :bad_request
      end

      # The member withdrawing, or the roster declining. Somebody else's request
      # is looked up only for whoever may answer it, so an outsider learns
      # nothing about who asked.
      def destroy
        unless params[:username].to_s.casecmp?(current_resource_owner.username)
          authorize! with: FleetSquadronRequestPolicy, to: :index?, context: {fleet: @fleet, fleet_squadron: @fleet_squadron}
        end

        request = find_request!

        authorize! request, context: {fleet: @fleet}

        if request.destroy
          head :no_content
        else
          render json: ValidationError.new("fleet_squadron_requests.destroy", errors: request.errors), status: :bad_request
        end
      end

      private def find_request!
        @fleet_squadron.fleet_squadron_requests
          .pending
          .joins(fleet_membership: :user)
          .find_by!(users: {normalized_username: params[:username].to_s.downcase})
      end

      private def viewer_membership
        @fleet.fleet_memberships.kept.accepted.find_by(user: current_resource_owner)
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end
    end
  end
end
