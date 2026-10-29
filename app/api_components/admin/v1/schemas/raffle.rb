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
            prize: {type: :string},
            translations: {type: :array, items: ::Admin::V1::Schemas::RaffleTranslation},
            # The code itself never leaves the server through this component.
            codeSet: {type: :boolean},
            maskedCode: {type: :string},
            images: {type: :array, items: ::Shared::V1::Schemas::MediaFile},
            startsAt: {type: :string, format: "date-time"},
            runDays: {type: :integer},
            endsAt: {type: :string, format: "date-time"},
            claimPeriodDays: {type: :integer},
            published: {type: :boolean},
            status: ::Shared::V1::Schemas::Enums::RaffleStatusEnum,
            # Left out once the raffle is concluded.
            previewUrl: {type: :string},
            entriesCount: {type: :integer},
            drawnAt: {type: :string, format: "date-time"},
            drawnBy: {type: :string},
            concludedAt: {type: :string, format: "date-time"},
            startAnnouncedAt: {type: :string, format: "date-time"},
            lastDayAnnouncedAt: {type: :string, format: "date-time"},
            socialPosts: ::Admin::V1::Schemas::RaffleSocialPosts,
            currentWinner: ::Admin::V1::Schemas::RaffleEntry,
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[id title translations codeSet images startsAt runDays endsAt claimPeriodDays published status entriesCount socialPosts createdAt updatedAt]
        })
      end
    end
  end
end
