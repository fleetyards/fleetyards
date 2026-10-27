# frozen_string_literal: true

module Admin
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
            # The code itself never leaves the server through this component.
            codeSet: {type: :boolean},
            maskedCode: {type: :string},
            startsAt: {type: :string, format: "date-time"},
            endsAt: {type: :string, format: "date-time"},
            claimPeriodDays: {type: :integer},
            published: {type: :boolean},
            status: ::Shared::V1::Schemas::Enums::RaffleStatusEnum,
            entriesCount: {type: :integer},
            drawnAt: {type: :string, format: "date-time"},
            drawnBy: {type: :string},
            concludedAt: {type: :string, format: "date-time"},
            currentWinner: ::Admin::V1::Schemas::RaffleEntry,
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id title codeSet startsAt endsAt claimPeriodDays published status entriesCount createdAt updatedAt]
        })
      end
    end
  end
end
