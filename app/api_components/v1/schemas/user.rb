# frozen_string_literal: true

module V1
  module Schemas
    class User
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          username: {type: :string},
          email: {type: :string},
          unconfirmedEmail: {type: :string},
          avatar: {"$ref": "#/components/schemas/MediaFile"},
          rsiHandle: {type: :string},
          rsiHandleVerified: {type: :boolean},
          citizenidProfileUrl: {type: :string},
          discord: {type: :string},
          youtube: {type: :string},
          twitch: {type: :string},
          guilded: {type: :string},
          homepage: {type: :string},
          location: {type: :string},
          currentSystem: {type: :string},
          currentSystemCode: {type: :string},
          saleNotify: {type: :boolean},
          publicHangar: {type: :boolean},
          publicHangarUrl: {type: :string},
          publicHangarLoaners: {type: :boolean},
          publicHangarStats: {type: :boolean},
          publicWishlist: {type: :boolean},
          publicWishlistUrl: {type: :string},
          hideOwner: {type: :boolean},
          twoFactorRequired: {type: :boolean},
          twoFactorQrCodeUrl: {type: :string},
          twoFactorProvisioningUrl: {type: :string},
          hangarUpdatedAt: {type: :string, format: "date-time"},
          resourceAccess: {type: :array, items: {type: :string}},
          authConnections: {type: :array, items: {type: :string}},
          passwordSetManually: {type: :boolean},
          oauthOnly: {type: :boolean},
          placeholderEmail: {type: :boolean},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[
          username email saleNotify publicHangar publicHangarLoaners publicHangarStats publicWishlist hideOwner
          twoFactorRequired resourceAccess authConnections passwordSetManually oauthOnly placeholderEmail createdAt updatedAt
        ]
      })
    end
  end
end
