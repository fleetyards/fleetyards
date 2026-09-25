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
            reviewStatus: ::V1::Schemas::Enums::PayoutEntryReviewStatusEnum,
            reviewedAt: {type: [:string, :null], format: "date-time"},
            reviewedBy: ::V1::Schemas::UserRef,
            declineReason: {type: [:string, :null]},
            participant: PayoutParticipant,
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          required: %w[id payoutLedgerId payoutParticipantId entryType reviewStatus amount description],
          additionalProperties: false
        })
      end
    end
  end
end
