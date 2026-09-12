# frozen_string_literal: true

module V1
  module Schemas
    module Payouts
      class PayoutEntry
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            payoutLedgerId: {type: :string, format: :uuid},
            payoutParticipantId: {type: :string, format: :uuid},
            entryType: ::V1::Schemas::Enums::PayoutEntryTypeEnum,
            amount: {type: :string},
            description: {type: :string},
            notes: {type: [:string, :null]},
            occurredAt: {type: [:string, :null], format: "date-time"},
            participant: PayoutParticipant,
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          required: %w[id payoutLedgerId payoutParticipantId entryType amount description],
          additionalProperties: false
        })
      end
    end
  end
end
