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
          startsAt: {type: :string, format: "date-time"},
          endsAt: {type: :string, format: "date-time"},
          claimPeriodDays: {type: :integer},
          status: ::Shared::V1::Schemas::Enums::RaffleStatusEnum,
          entriesCount: {type: :integer},
          drawnAt: {type: :string, format: "date-time"},
          concludedAt: {type: :string, format: "date-time"},
          currentWinner: ::V1::Schemas::RaffleWinner,
          forfeitedWinners: {type: :array, items: ::V1::Schemas::RaffleWinner},
          conditionsVersion: {type: :string},
          contacts: ::V1::Schemas::RaffleContacts,
          # Whether the signed-in reader entered, and whether the win is theirs.
          entered: {type: :boolean},
          won: {type: :boolean},
          claimable: {type: :boolean},
          claimed: {type: :boolean}
        },
        additionalProperties: false,
        required: %w[id title startsAt endsAt claimPeriodDays status entriesCount forfeitedWinners conditionsVersion contacts entered won claimable claimed]
      })
    end
  end
end
