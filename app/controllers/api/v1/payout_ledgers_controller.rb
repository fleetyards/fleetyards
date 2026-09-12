# frozen_string_literal: true

module Api
  module V1
    class PayoutLedgersController < ::Api::BaseController
      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read", "user" },
        unless: :user_signed_in?,
        only: %i[show show_for_subject balances]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write", "user:write" },
        unless: :user_signed_in?,
        only: %i[create settle reopen]

      before_action :set_subject, only: %i[show_for_subject create]
      before_action :set_payout_ledger, only: %i[show balances settle reopen]
      before_action :check_tour_payouts_feature

      # GET /fleets/:fleet_slug/events/:slug/payouts
      # GET /tours/:tour_slug/payouts
      #
      # A subject has at most one ledger, so this is the lookup that tells the
      # frontend whether to show the ledger or an offer to open one.
      def show_for_subject
        @payout_ledger = @subject.payout_ledger

        if @payout_ledger.blank?
          render json: {code: "not_found", message: "No payout ledger for this subject"}, status: :not_found
          return
        end

        authorize! @payout_ledger, with: PayoutLedgerPolicy, to: :show?

        render :show
      end

      def show
        authorize! @payout_ledger, with: PayoutLedgerPolicy, to: :show?
      end

      def create
        @payout_ledger = @subject.build_payout_ledger(ledger_params)

        authorize! @payout_ledger, with: PayoutLedgerPolicy, context: {payout_ledger: @payout_ledger, fleet: subject_fleet}

        if @payout_ledger.save
          @payout_ledger.seed_participants_from_subject!
          render :show, status: :created
        else
          render json: ValidationError.new("payout_ledgers.create", errors: @payout_ledger.errors), status: :bad_request
        end
      end

      def balances
        authorize! @payout_ledger, with: PayoutLedgerPolicy, to: :balances?

        @settlement = @payout_ledger.settlement
      end

      def settle
        authorize! @payout_ledger, with: PayoutLedgerPolicy, to: :settle?

        if @payout_ledger.settled?
          render json: {code: "already_settled", message: "This ledger is already settled"}, status: :conflict
          return
        end

        @payout_ledger.settle!(current_resource_owner)
        render :show
      end

      def reopen
        authorize! @payout_ledger, with: PayoutLedgerPolicy, to: :reopen?

        unless @payout_ledger.settled?
          render json: {code: "not_settled", message: "This ledger is not settled"}, status: :conflict
          return
        end

        @payout_ledger.reopen!
        render :show
      end

      private def ledger_params
        authorized(params, with: PayoutLedgerPolicy)
      end

      private def set_payout_ledger
        @payout_ledger = PayoutLedger.includes(:subject).find(params[:id])
      end

      private def set_subject
        @subject =
          if params[:tour_slug].present?
            authorized_scope(Tour.all).find_by!(slug: params[:tour_slug])
          else
            fleet = authorized_scope(Fleet.all).find_by!(slug: params[:fleet_slug])
            authorize! fleet, to: :show?
            fleet.fleet_events.find_by!(slug: params[:fleet_event_slug])
          end
      end

      private def subject_fleet
        @subject.is_a?(FleetEvent) ? @subject.fleet : nil
      end

      private def check_tour_payouts_feature
        fleet = @payout_ledger&.fleet || subject_fleet
        actors = fleet ? [fleet] : []
        return if feature_enabled?("tour_payouts", *actors)

        render json: {code: "forbidden", message: "This feature is not available"}, status: :forbidden
      end
    end
  end
end
