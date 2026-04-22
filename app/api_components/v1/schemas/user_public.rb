# frozen_string_literal: true

module V1
  module Schemas
    class UserPublic
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          username: {type: :string},
          avatar: {"$ref": "#/components/schemas/MediaFile"},
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
          publicWishlist: {type: :boolean}
        },
        additionalProperties: false,
        required: %w[username publicHangarLoaners publicHangarStats publicWishlist]
      })
    end
  end
end
