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
          citizenidProfileUrl: {type: :string},
          discord: {type: :string},
          youtube: {type: :string},
          twitch: {type: :string},
          guilded: {type: :string},
          homepage: {type: :string},
          publicHangarLoaners: {type: :boolean},
          publicHangarStats: {type: :boolean},
          publicWishlist: {type: :boolean},
          supporter: {type: :boolean}
        },
        additionalProperties: false,
        required: %w[username publicHangarLoaners publicHangarStats publicWishlist supporter]
      })
    end
  end
end
