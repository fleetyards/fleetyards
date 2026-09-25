# frozen_string_literal: true

module Api
  module V1
    class PayoutEntriesController < ::Api::BaseController
      include PayoutLedgerScoped
      include FleetSubscriptionConcern

      after_action -> { pagination_header(:payout_entries) }, only: %i[index]

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read", "user" },
        unless: :user_signed_in?,
        only: %i[index]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write", "user:write" },
        unless: :user_signed_in?,
        only: %i[create update destroy approve decline]

      before_action :set_payout_ledger
      before_action :check_tour_payouts_feature
      before_action -> { require_fleet_subscription(:tours) }
      before_action :set_payout_entry, only: %i[update destroy approve decline]

      def index
        authorize! with: PayoutEntryPolicy, context: ledger_context

        query_params = params.fetch(:q, {}).permit(:description_cont, :entry_type_eq, :review_status_eq, :payout_participant_id_eq, :s)
        normalize_sort_params(query_params)
        query_params["sorts"] = sorting_params(PayoutEntry, query_params["sorts"])

        @q = @payout_ledger.payout_entries
          .includes(:reviewed_by, payout_participant: [:user, :fleet])
          .ransack(query_params)

        @payout_entries = result_with_pagination(@q.result(distinct: true), per_page(PayoutEntry))
      end

      def create
        @payout_entry = @payout_ledger.payout_entries.new(payout_entry_params)
        @payout_entry.recorded_by = current_resource_owner

        authorize! @payout_entry, with: PayoutEntryPolicy, context: ledger_context

        @payout_entry.assign_review_status(by_manager: ledger_manager?)

        if @payout_entry.save
          render :show, status: :created
        else
          render json: ValidationError.new("payout_entries.create", errors: @payout_entry.errors), status: :bad_request
        end
      end

      # Assigned before the check, the way create builds the record first: the
      # participant an entry names is exactly what the policy has to weigh, and
      # authorizing the row as it stands would wave through a move onto someone
      # else.
      def update
        @payout_entry.assign_attributes(payout_entry_params)

        authorize! @payout_entry, with: PayoutEntryPolicy, context: ledger_context

        @payout_entry.assign_review_status(by_manager: ledger_manager?)

        if @payout_entry.save
          render :show
        else
          render json: ValidationError.new("payout_entries.update", errors: @payout_entry.errors), status: :bad_request
        end
      end

      def destroy
        authorize! @payout_entry, with: PayoutEntryPolicy, context: ledger_context

        if @payout_entry.destroy
          render :show
        else
          render json: ValidationError.new("payout_entries.destroy", errors: @payout_entry.errors), status: :bad_request
        end
      end

      def approve
        authorize! @payout_entry, with: PayoutEntryPolicy, context: ledger_context, to: :review?

        @payout_entry.approve!(current_resource_owner)

        render :show
      rescue ActiveRecord::RecordInvalid
        render json: ValidationError.new("payout_entries.approve", errors: @payout_entry.errors), status: :bad_request
      end

      def decline
        authorize! @payout_entry, with: PayoutEntryPolicy, context: ledger_context, to: :review?

        @payout_entry.decline!(current_resource_owner, reason: params[:reason])

        render :show
      rescue ActiveRecord::RecordInvalid
        render json: ValidationError.new("payout_entries.decline", errors: @payout_entry.errors), status: :bad_request
      end

      private def ledger_manager?
        PayoutLedgerPolicy.new(@payout_ledger, user: current_resource_owner, **ledger_context).manage?
      end

      # Defined here rather than left to PayoutLedgerScoped: both it and
      # FleetSubscriptionConcern define this, and the concern is included last,
      # so its `@fleet` default -- nil here -- would win the lookup and skip
      # enforcement. A method on the class beats either module.
      private def subscription_fleet
        @payout_ledger&.fleet
      end

      private def payout_entry_params
        authorized(params, with: PayoutEntryPolicy, context: ledger_context)
      end

      private def set_payout_entry
        @payout_entry = @payout_ledger.payout_entries.find(params[:id])
      end
    end
  end
end
