# frozen_string_literal: true

module Api
  module V1
    class ToursController < ::Api::BaseController
      after_action -> { pagination_header(:tours) }, only: %i[index]

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "user" },
        unless: :user_signed_in?,
        only: %i[index show find_by_invite]
      before_action -> { doorkeeper_authorize! "user:write" },
        unless: :user_signed_in?,
        only: %i[create update destroy settle reopen cancel rotate_invite join]

      before_action :set_viewer
      before_action :check_tour_payouts_feature
      before_action :set_tour, only: %i[show update destroy settle reopen cancel rotate_invite]

      def index
        authorize! with: TourPolicy

        query_params = params.fetch(:q, {}).permit(:title_cont, :status_eq, :s)
        normalize_sort_params(query_params)
        query_params["sorts"] = sorting_params(Tour, query_params["sorts"])

        @q = authorized_scope(Tour.all).includes(:created_by).ransack(query_params)

        @tours = result_with_pagination(@q.result(distinct: true), per_page(Tour))
      end

      def show
        authorize! @tour
      end

      def create
        @tour = Tour.new(tour_params)
        @tour.created_by = current_resource_owner

        authorize! @tour

        if @tour.save
          # A tour with no ledger has nowhere to record anything, and its
          # organiser is its first participant, so both are part of creating it
          # rather than a second step the frontend has to remember.
          ledger = @tour.create_payout_ledger!
          ledger.seed_participants_from_subject!

          render :show, status: :created
        else
          render json: ValidationError.new("tours.create", errors: @tour.errors), status: :bad_request
        end
      end

      def update
        authorize! @tour

        if @tour.update(tour_params)
          render :show
        else
          render json: ValidationError.new("tours.update", errors: @tour.errors), status: :bad_request
        end
      end

      def destroy
        authorize! @tour

        if @tour.destroy
          render :show
        else
          render json: ValidationError.new("tours.destroy", errors: @tour.errors), status: :bad_request
        end
      end

      def settle
        authorize! @tour, to: :settle?

        @tour.payout_ledger&.settle!(current_resource_owner)
        @tour.settle!

        render :show
      end

      def reopen
        authorize! @tour, to: :reopen?

        @tour.payout_ledger&.reopen!
        @tour.reopen!

        render :show
      end

      def cancel
        authorize! @tour, to: :cancel?

        @tour.cancel!
        render :show
      end

      def rotate_invite
        authorize! @tour, to: :rotate_invite?

        @tour.rotate_invite_token!
        render :show
      end

      # The landing page behind an invite link, before the viewer commits to
      # joining. Deliberately outside the relation scope -- someone who has not
      # joined yet is not on the tour, and could not see it otherwise.
      def find_by_invite
        @tour = Tour.active.find_by!(invite_token: params[:token])

        authorize! @tour, to: :find_by_invite?

        render :show
      end

      def join
        @tour = Tour.active.find_by!(invite_token: params[:token])

        authorize! @tour, to: :join?

        ledger = @tour.payout_ledger || @tour.create_payout_ledger!

        unless ledger.open?
          render json: {code: "settled", message: "This tour is already settled"}, status: :conflict
          return
        end

        participant = ledger.payout_participants.find_or_initialize_by(user_id: current_resource_owner.id)

        if participant.persisted? || participant.save
          render :show
        else
          render json: ValidationError.new("tours.join", errors: participant.errors), status: :bad_request
        end
      end

      # The invite token is only rendered for the organiser, and a jbuilder view
      # cannot reach current_resource_owner on its own.
      private def set_viewer
        @viewer = current_resource_owner
      end

      private def tour_params
        authorized(params, with: TourPolicy)
      end

      private def set_tour
        @tour = Tour.includes(payout_ledger: :payout_participants).find_by!(slug: params[:slug])
      end

      private def check_tour_payouts_feature
        return if feature_enabled?("tour_payouts")

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
