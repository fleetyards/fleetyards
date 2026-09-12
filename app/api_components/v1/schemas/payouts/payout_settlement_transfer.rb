# frozen_string_literal: true

module V1
  module Schemas
    module Payouts
      # The preview shape a still-open ledger computes on the fly. Deliberately
      # not PayoutTransfer: that one is a persisted row with an id and a
      # confirmation, and this has neither until the ledger is settled.
      class PayoutSettlementTransfer
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            from: PayoutParticipant,
            to: PayoutParticipant,
            amount: {type: :string}
          },
          required: %w[from to amount],
          additionalProperties: false
        })
      end
    end
  end
end
