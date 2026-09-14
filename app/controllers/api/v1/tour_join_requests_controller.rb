# frozen_string_literal: true

module Api
  module V1
    class TourJoinRequestsController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "user" },
        unless: :user_signed_in?,
        only: %i[index]
      before_action -> { doorkeeper_authorize! "user:write" },
        unless: :user_signed_in?,
        only: %i[create approve decline destroy]

      before_action :set_tour
      before_action :check_tour_payouts_feature
      before_action :set_tour_join_request, only: %i[approve decline destroy]

      # Only the ones still waiting for an answer: a declined request is kept as
      # the record of the answer, not as something left to do.
      def index
        authorize! with: TourJoinRequestPolicy, context: tour_context

        @tour_join_requests = @tour.join_requests.pending.includes(user: {avatar_attachment: :blob}).order(:created_at)
      end

      def create
        @tour_join_request = @tour.join_requests.new(user: current_resource_owner)

        authorize! @tour_join_request, with: TourJoinRequestPolicy, context: tour_context

        if @tour_join_request.save
          render :show, status: :created
        else
          render json: ValidationError.new("tour_join_requests.create", errors: @tour_join_request.errors), status: :bad_request
        end
      rescue ActiveRecord::RecordNotUnique
        # Two tabs raced the pending-request validation. The partial unique
        # index is what actually decides, and the answer it forces is the one
        # the validation would have given a moment later.
        @tour_join_request.errors.add(:base, :already_requested)

        render json: ValidationError.new("tour_join_requests.create", errors: @tour_join_request.errors), status: :bad_request
      end

      # Guarded rather than idempotent, the same way settling is: the answer
      # adds a participant, and the head count is what every share is divided
      # by. `approve_by` answers false when the ledger closed in between.
      def approve
        authorize! @tour_join_request, with: TourJoinRequestPolicy, to: :approve?, context: tour_context

        unless @tour_join_request.approve_by(current_resource_owner)
          render json: {code: "cannot_approve", message: "This request can no longer be approved"}, status: :conflict
          return
        end

        render :show
      end

      def decline
        authorize! @tour_join_request, with: TourJoinRequestPolicy, to: :decline?, context: tour_context

        unless @tour_join_request.decline_by(current_resource_owner)
          render json: {code: "cannot_decline", message: "This request can no longer be declined"}, status: :conflict
          return
        end

        render :show
      end

      def destroy
        authorize! @tour_join_request, with: TourJoinRequestPolicy, context: tour_context

        if @tour_join_request.destroy
          render :show
        else
          render json: ValidationError.new("tour_join_requests.destroy", errors: @tour_join_request.errors), status: :bad_request
        end
      end

      private def tour_context
        {tour: @tour, fleet: @tour&.fleet}
      end

      # Addressed by the tour's slug alone, like everything else a tour does
      # outside its fleet's own list. `show?` is the gate on finding the tour at
      # all; who may ask and who may answer is the policy's business.
      private def set_tour
        @tour = Tour.find_by!(slug: params[:tour_slug])

        authorize! @tour, with: TourPolicy, to: :show?
      end

      private def set_tour_join_request
        @tour_join_request = @tour.join_requests.find(params[:id])
      end

      # Asking onto a tour only exists on the fleet surface, so it wants both
      # flags -- tour_payouts for tours at all, fleet_tours for a fleet running
      # them as a fleet.
      private def check_tour_payouts_feature
        actors = @tour&.fleet ? [@tour.fleet] : []

        return if feature_enabled?("tour_payouts", *actors) && feature_enabled?("fleet_tours", *actors)

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
