# frozen_string_literal: true

module Api
  module V1
    class PayoutEntriesController < ::Api::BaseController
      include PayoutLedgerScoped

      after_action -> { pagination_header(:payout_entries) }, only: %i[index]

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read", "user" },
        unless: :user_signed_in?,
        only: %i[index]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write", "user:write" },
        unless: :user_signed_in?,
        only: %i[create update destroy]

      before_action :set_payout_ledger
      before_action :check_tour_payouts_feature
      before_action :set_payout_entry, only: %i[update destroy]

      def index
        authorize! with: PayoutEntryPolicy, context: ledger_context

        query_params = params.fetch(:q, {}).permit(:description_cont, :entry_type_eq, :payout_participant_id_eq, :s)
        normalize_sort_params(query_params)
        query_params["sorts"] = sorting_params(PayoutEntry, query_params["sorts"])

        @q = @payout_ledger.payout_entries
          .includes(payout_participant: :user)
          .ransack(query_params)

        @payout_entries = result_with_pagination(@q.result(distinct: true), per_page(PayoutEntry))
      end

      def create
        @payout_entry = @payout_ledger.payout_entries.new(payout_entry_params)
        @payout_entry.recorded_by = current_resource_owner

        authorize! @payout_entry, with: PayoutEntryPolicy, context: ledger_context

        if @payout_entry.save
          render :show, status: :created
        else
          render json: ValidationError.new("payout_entries.create", errors: @payout_entry.errors), status: :bad_request
        end
      end

      def update
        authorize! @payout_entry, with: PayoutEntryPolicy, context: ledger_context

        if @payout_entry.update(payout_entry_params)
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

      private def payout_entry_params
        authorized(params, with: PayoutEntryPolicy, context: ledger_context)
      end

      private def set_payout_entry
        @payout_entry = @payout_ledger.payout_entries.find(params[:id])
      end
    end
  end
end
