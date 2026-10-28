# frozen_string_literal: true

module V1
  module Schemas
    class Raffle
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          title: {type: :string},
          description: {type: :string},
          prize: ::Shared::V1::Schemas::RafflePrize,
          images: {type: :array, items: ::Shared::V1::Schemas::MediaFile},
          startsAt: {type: :string, format: "date-time"},
          endsAt: {type: :string, format: "date-time"},
          runDays: {type: :integer},
          claimPeriodDays: {type: :integer},
          status: ::Shared::V1::Schemas::Enums::RaffleStatusEnum,
          entriesCount: {type: :integer},
          drawnAt: {type: :string, format: "date-time"},
          concludedAt: {type: :string, format: "date-time"},
          currentWinner: ::V1::Schemas::RaffleWinner,
          forfeitedWinners: {type: :array, items: ::V1::Schemas::RaffleWinner},
          conditionsVersion: {type: :string},
          # Whether the signed-in reader entered, and whether the win is theirs.
          entered: {type: :boolean},
          won: {type: :boolean},
          claimable: {type: :boolean},
          claimed: {type: :boolean}
        },
        additionalProperties: false,
        required: %w[id title images startsAt endsAt runDays claimPeriodDays status entriesCount forfeitedWinners conditionsVersion entered won claimable claimed]
      })
    end
  end
end
