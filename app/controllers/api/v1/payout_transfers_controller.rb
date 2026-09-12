# frozen_string_literal: true

module Api
  module V1
    class PayoutTransfersController < ::Api::BaseController
      include PayoutLedgerScoped

      before_action :authenticate_user!, only: []
      before_action -> { doorkeeper_authorize! "fleet", "fleet:read", "user" },
        unless: :user_signed_in?,
        only: %i[index]
      before_action -> { doorkeeper_authorize! "fleet", "fleet:write", "user:write" },
        unless: :user_signed_in?,
        only: %i[confirm unconfirm]

      before_action :set_payout_ledger
      before_action :check_tour_payouts_feature
      before_action :set_payout_transfer, only: %i[confirm unconfirm]

      def index
        authorize! with: PayoutTransferPolicy, context: ledger_context

        @payout_transfers = @payout_ledger.payout_transfers
          .includes(from_participant: :user, to_participant: :user)
          .order(:created_at)
      end

      def confirm
        authorize! @payout_transfer, with: PayoutTransferPolicy, context: ledger_context

        @payout_transfer.confirm!(current_resource_owner)
        render :show
      end

      def unconfirm
        authorize! @payout_transfer, with: PayoutTransferPolicy, context: ledger_context

        @payout_transfer.unconfirm!
        render :show
      end

      private def set_payout_transfer
        @payout_transfer = @payout_ledger.payout_transfers.find(params[:id])
      end
    end
  end
end
