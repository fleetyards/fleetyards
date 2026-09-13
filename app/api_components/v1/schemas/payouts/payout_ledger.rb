# frozen_string_literal: true

module V1
  module Schemas
    module Payouts
      class PayoutLedger
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            subjectType: ::V1::Schemas::Enums::PayoutLedgerSubjectTypeEnum,
            subjectId: {type: :string, format: :uuid},
            status: ::V1::Schemas::Enums::PayoutLedgerStatusEnum,
            notes: {type: [:string, :null]},
            settledAt: {type: [:string, :null], format: "date-time"},
            participantsCount: {type: :integer},
            entriesCount: {type: :integer},
            totalIncome: {type: :string},
            totalExpenses: {type: :string},
            profit: {type: :string},
            participants: {type: :array, items: PayoutParticipant},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          required: %w[id subjectType subjectId status],
          additionalProperties: false
        })
      end
    end
  end
end
