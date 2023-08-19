# frozen_string_literal: true

module V1
  module Schemas
    class UserBase
      include SchemaConcern

      schema_hidden true

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
          hangarUpdatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[
          username email saleNotify publicHangar publicHangarLoaners publicWishlist hideOwner
          twoFactorRequired
        ]
      })
    end
  end
end
