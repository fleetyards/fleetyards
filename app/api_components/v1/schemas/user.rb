# frozen_string_literal: true

module V1
  module Schemas
    class User
      include SchemaConcern

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          username: {type: :string},
          email: {type: :string},
          unconfirmedEmail: {type: :string},
          avatar: {type: :string},
          rsiHandle: {type: :string},
          discord: {type: :string},
          youtube: {type: :string},
          twitch: {type: :string},
          guilded: {type: :string},
          homepage: {type: :string},
          saleNotify: {type: :boolean},
          publicHangar: {type: :boolean},
          publicHangarUrl: {type: :string},
          publicHangarLoaners: {type: :boolean},
          publicWishlist: {type: :boolean},
          publicWishlistUrl: {type: :string},
          hideOwner: {type: :boolean},
          twoFactorRequired: {type: :boolean},
          twoFactorQrCodeUrl: {type: :string},
          twoFactorProvisioningUrl: {type: :string},
          hangarUpdatedAt: {type: :string, format: "date-time"},
          resourceAccess: {type: :array, items: {type: :string}},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[
          username email saleNotify publicHangar publicHangarLoaners publicWishlist hideOwner
          twoFactorRequired resourceAccess createdAt updatedAt
        ]
      })
    end
  end
end
