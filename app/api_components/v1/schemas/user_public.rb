# frozen_string_literal: true

module V1
  module Schemas
    class UserPublic
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          username: {type: :string},
          avatar: ::Shared::V1::Schemas::MediaFile,
          rsiHandle: {type: :string},
          rsiHandleVerified: {type: :boolean},
          rsiHandleVerifiedVia: ::V1::Schemas::Enums::RsiHandleVerifiedViaEnum,
          citizenidProfileUrl: {type: :string},
          discord: {type: :string},
          youtube: {type: :string},
          twitch: {type: :string},
          guilded: {type: :string},
          homepage: {type: :string},
          publicHangarLoaners: {type: :boolean},
          publicHangarStats: {type: :boolean},
          hangarDefaultSort: ::V1::Schemas::Enums::NullableVehicleSortEnum,
          publicWishlist: {type: :boolean},
          supporter: {type: :boolean},
          maintainer: {type: :boolean},
          supporterTier: {type: :integer},
          supporterRecurring: {type: :boolean},
          online: {type: :boolean, description: "Only for the user's friends and fleet mates"}
        },
        additionalProperties: false,
        required: %w[username publicHangarLoaners publicHangarStats hangarDefaultSort publicWishlist supporter maintainer supporterTier supporterRecurring]
      })
    end
  end
end
