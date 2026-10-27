# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class RaffleEntry
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            username: {type: :string},
            accountDeleted: {type: :boolean},
            maskedEmail: {type: :string},
            conditionsAcceptedAt: {type: :string, format: "date-time"},
            conditionsVersion: {type: :string},
            drawPosition: {type: :integer},
            wonAt: {type: :string, format: "date-time"},
            claimDeadlineAt: {type: :string, format: "date-time"},
            claimedAt: {type: :string, format: "date-time"},
            claimedBy: {type: :string},
            forfeitedAt: {type: :string, format: "date-time"},
            verificationSentAt: {type: :string, format: "date-time"},
            claimable: {type: :boolean},
            createdAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id username accountDeleted conditionsAcceptedAt conditionsVersion claimable createdAt]
        })
      end
    end
  end
end
