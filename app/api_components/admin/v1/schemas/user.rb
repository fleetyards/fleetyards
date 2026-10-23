# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class User
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            username: {type: :string},
            displayName: {type: :string},
            email: {type: :string},
            unconfirmedEmail: {type: :string},
            avatar: ::Shared::V1::Schemas::MediaFile,
            rsiHandle: {type: :string},
            rsiHandleVerified: {type: :boolean},
            rsiHandleVerifiedVia: ::Admin::V1::Schemas::Enums::RsiHandleVerifiedViaEnum,
            rsiHandleVerifiedAt: {type: :string, format: "date-time"},
            citizenidProfileUrl: {type: :string},
            discord: {type: :string},
            youtube: {type: :string},
            twitch: {type: :string},
            homepage: {type: :string},
            publicHangar: {type: :boolean},
            publicHangarUrl: {type: :string},
            publicHangarLoaners: {type: :boolean},
            publicWishlist: {type: :boolean},
            publicWishlistUrl: {type: :string},
            hideOwner: {type: :boolean},
            maintainer: {type: :boolean},
            supporter: {type: :boolean},
            supporterTier: {type: :integer},
            supporterRecurring: {type: :boolean},
            supporterUntil: {type: :string, format: :date},
            fleetTierUntil: {type: :string, format: :date},
            fleetTierOngoing: {type: :boolean},
            twoFactorRequired: {type: :boolean},
            twoFactorQrCodeUrl: {type: :string},
            twoFactorProvisioningUrl: {type: :string},
            hangarUpdatedAt: {type: :string, format: "date-time"},
            confirmedAt: {type: :string, format: "date-time"},
            lastActiveAt: {type: :string, format: "date-time"},
            online: {type: :boolean},
            createdAt: {type: :string, format: "date-time"},
            updatedAt: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[
            username email publicHangar publicHangarLoaners publicWishlist hideOwner
            maintainer supporter supporterTier supporterRecurring fleetTierOngoing twoFactorRequired createdAt updatedAt
          ]
        })
      end
    end
  end
end
