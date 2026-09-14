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
      before_action :set_fleet
      before_action :check_tour_payouts_feature
      before_action :set_tour, only: %i[show update destroy settle reopen cancel rotate_invite]

      def index
        authorize! with: TourPolicy, context: {fleet: @fleet}

        query_params = params.fetch(:q, {}).permit(:title_cont, :status_eq, :s)
        normalize_sort_params(query_params)
        query_params["sorts"] = sorting_params(Tour, query_params["sorts"])

        @q = index_scope.includes(created_by: {avatar_attachment: :blob}, fleet: {logo_attachment: :blob}).ransack(query_params)

        @tours = result_with_pagination(@q.result(distinct: true), per_page(Tour))
      end

      def show
        authorize! @tour
      end

      def create
        @tour = Tour.new(tour_params)
        @tour.created_by = current_resource_owner
        @tour.fleet = @fleet

        authorize! @tour

        # A tour with no ledger has nowhere to record anything, and its organiser
        # is its first participant, so all three happen together rather than
        # leaving a half-built tour the UI cannot repair.
        created = ApplicationRecord.transaction do
          @tour.save && @tour.create_payout_ledger!.seed_participants_from_subject!
        end

        if created
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

      # Guarded rather than idempotent: settling again would run
      # PayoutLedger#settle!, whose first statement deletes the transfers --
      # taking every confirmation people had already ticked off with them.
      def settle
        authorize! @tour, to: :settle?

        ledger = @tour.payout_ledger

        unless @tour.may_settle? && ledger&.open?
          render json: {code: "cannot_settle", message: "This tour cannot be settled"}, status: :conflict
          return
        end

        # Carries the tour's own transition with it, so this and
        # PUT /payouts/:id/settle end in the same place. It moves the ledger's
        # own `subject` instance, which is not the one loaded here, and answers
        # false if another request settled it between the guard and the lock.
        unless ledger.settle!(current_resource_owner)
          render json: {code: "cannot_settle", message: "This tour cannot be settled"}, status: :conflict
          return
        end

        @tour.reload

        render :show
      end

      def reopen
        authorize! @tour, to: :reopen?

        ledger = @tour.payout_ledger

        unless @tour.may_reopen? && ledger&.settled?
          render json: {code: "cannot_reopen", message: "This tour is not settled"}, status: :conflict
          return
        end

        unless ledger.reopen!
          render json: {code: "cannot_reopen", message: "This tour is not settled"}, status: :conflict
          return
        end

        @tour.reload

        render :show
      end

      def cancel
        authorize! @tour, to: :cancel?

        unless @tour.may_cancel?
          render json: {code: "cannot_cancel", message: "This tour cannot be cancelled"}, status: :conflict
          return
        end

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
        @tour = invite_scope.find_by!(invite_token: params[:token])

        authorize! @tour, to: :find_by_invite?

        render :show
      end

      def join
        @tour = invite_scope.find_by!(invite_token: params[:token])

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
      rescue ActiveRecord::RecordNotUnique
        # Two tabs raced the uniqueness check; the other one already added them,
        # which is the outcome this asked for.
        render :show
      end

      # The invite page names and pictures whoever is inviting, so the organiser
      # and their avatar come along with the lookup.
      private def invite_scope
        Tour.active.includes(created_by: {avatar_attachment: :blob})
      end

      # The invite token is only rendered for whoever may hand it out, and a
      # jbuilder view cannot reach current_resource_owner on its own.
      private def set_viewer
        @viewer = current_resource_owner
        @payout_manager_fleet_ids = payout_manager_fleet_ids
      end

      # Resolved once for the whole response rather than per tour: the index
      # renders a page of them, and a membership lookup each would be a query
      # per row. A viewer belongs to a handful of fleets at most.
      private def payout_manager_fleet_ids
        return [] if @viewer.blank?

        @viewer.fleet_memberships.kept.accepted
          .select { |membership| membership.has_access?(["fleet:manage", "fleet:payouts:manage"]) }
          .map(&:fleet_id)
      end

      private def tour_params
        authorized(params, with: TourPolicy)
      end

      private def set_tour
        @tour = tour_scope
          .includes(created_by: {avatar_attachment: :blob}, fleet: {logo_attachment: :blob}, payout_ledger: :payout_participants)
          .find_by!(slug: params[:slug])
      end

      # Under a fleet, only that fleet's own tours are addressable -- otherwise
      # /fleets/other-org/tours/<slug> would render a tour the URL says nothing
      # about, and the page would name the wrong fleet around it.
      private def tour_scope
        @fleet&.tours || Tour.all
      end

      # The standalone list is the signed-in user's own tours, so it goes
      # through the relation scope. A fleet's list is every tour the fleet
      # owns -- `index?` already decided the viewer may see them, the same way
      # FleetEventsController lists a fleet's events.
      private def index_scope
        return @fleet.tours if @fleet

        authorized_scope(Tour.all)
      end

      private def set_fleet
        return if params[:fleet_slug].blank?

        @fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])
        authorize! @fleet, to: :show?
      end

      private def check_tour_payouts_feature
        return if feature_enabled?("tour_payouts", *[@fleet].compact)

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
