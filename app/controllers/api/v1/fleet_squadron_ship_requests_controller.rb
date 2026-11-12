# frozen_string_literal: true

module Api
  module V1
    # A squadron's leadership asking members for particular ships. The roster's
    # managers see every open request; a member sees the ones addressed to them.
    class FleetSquadronShipRequestsController < ::Api::BaseController
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
        authorize! with: FleetSquadronShipRequestPolicy, context: {fleet: @fleet, fleet_squadron: @fleet_squadron}

        scope = squadron_requests
        unless allowed_to?(:manages_roster?, with: FleetSquadronShipRequestPolicy, context: {fleet: @fleet, fleet_squadron: @fleet_squadron})
          scope = scope.where(fleet_squadron_memberships: {fleet_membership_id: viewer_membership&.id})
        end

        @fleet_squadron_ship_requests = scope
          .includes(vehicle: :model, requested_by: :user, fleet_squadron_membership: {fleet_membership: FleetMembership::ROSTER_PRELOADS})
          .order(created_at: :asc)
      end

      def create
        row = @fleet_squadron.fleet_squadron_memberships
          .joins(fleet_membership: :user)
          .merge(FleetMembership.kept.accepted)
          .find_by(users: {normalized_username: params[:username].to_s.downcase})

        @fleet_squadron_ship_request = FleetSquadronShipRequest.new(
          fleet_squadron_membership: row,
          vehicle_id: params[:vehicleId] || params[:vehicle_id],
          requested_by: viewer_membership
        )

        authorize! @fleet_squadron_ship_request, context: {fleet: @fleet, fleet_squadron: @fleet_squadron}

        raise ActiveRecord::RecordNotFound if row.blank?

        if @fleet_squadron_ship_request.save
          render :show, status: :created
        else
          render json: ValidationError.new("fleet_squadron_ship_requests.create", errors: @fleet_squadron_ship_request.errors), status: :bad_request
        end
      end

      def accept
        request = find_request!

        authorize! request, context: {fleet: @fleet, fleet_squadron: @fleet_squadron}

        request.accept!

        head :no_content
      rescue ActiveRecord::RecordInvalid => e
        render json: ValidationError.new("fleet_squadron_ship_requests.accept", errors: e.record.errors), status: :bad_request
      end

      def destroy
        request = find_request!

        authorize! request, context: {fleet: @fleet, fleet_squadron: @fleet_squadron}

        if request.destroy
          head :no_content
        else
          render json: ValidationError.new("fleet_squadron_ship_requests.destroy", errors: request.errors), status: :bad_request
        end
      end

      private def squadron_requests
        FleetSquadronShipRequest.open.where(fleet_squadron_memberships: {fleet_squadron_id: @fleet_squadron.id})
      end

      private def find_request!
        squadron_requests.find(params[:id])
      end

      private def viewer_membership
        @viewer_membership ||= @fleet.fleet_memberships.kept.accepted.find_by(user: current_resource_owner)
      end

      private def set_fleet
        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])

        authorize! @fleet, to: :show?
      end
    end
  end
end
