# frozen_string_literal: true

module V1
  module Schemas
    class MyRaffleEntry
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          raffleId: {type: :string, format: :uuid},
          raffleTitle: {type: :string},
          prize: {type: :string},
          raffleStatus: ::Shared::V1::Schemas::Enums::RaffleStatusEnum,
          endsAt: {type: :string, format: "date-time"},
          enteredAt: {type: :string, format: "date-time"},
          outcome: ::V1::Schemas::Enums::RaffleEntryOutcomeEnum,
          claimDeadlineAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id raffleId raffleTitle raffleStatus endsAt enteredAt outcome]
      })
    end
  end
end
