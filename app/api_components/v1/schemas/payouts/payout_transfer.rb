# frozen_string_literal: true

module V1
  module Schemas
    module Payouts
      class PayoutTransfer
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            payoutLedgerId: {type: :string, format: :uuid},
            amount: {type: :string},
            confirmed: {type: :boolean},
            confirmedAt: {type: [:string, :null], format: "date-time"},
            from: PayoutParticipant,
            to: PayoutParticipant,
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          required: %w[id payoutLedgerId amount confirmed from to],
          additionalProperties: false
        })
      end
    end
  end
end
