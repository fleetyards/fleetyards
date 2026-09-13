# frozen_string_literal: true

module V1
  module Schemas
    module Payouts
      # The derived view of an open ledger: every balance, and the transfers
      # that would settle them. Recomputed per request rather than stored.
      class PayoutSettlement
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            totalIncome: {type: :string},
            totalExpenses: {type: :string},
            profit: {type: :string},
            balances: {type: :array, items: PayoutBalance},
            transfers: {type: :array, items: PayoutSettlementTransfer}
          },
          required: %w[totalIncome totalExpenses profit balances transfers],
          additionalProperties: false
        })
      end
    end
  end
end
